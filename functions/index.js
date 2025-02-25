const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

exports.processNotificationQueue = onDocumentCreated(
  {
    document: 'notifications_queue/{notificationId}',
    region: 'us-central1',
    maxInstances: 10,
    timeoutSeconds: 540
  },
  async (event) => {
    try {
      const snapshot = event.data;
      if (!snapshot) {
        console.error("No document snapshot available");
        return;
      }

      const data = snapshot.data();
      console.log("Processing notification batch with", data?.tokens?.length, "tokens");

      if (!data?.tokens?.length) {
        console.log("Empty tokens array - deleting document");
        await snapshot.ref.delete();
        return;
      }

      // Configure platform-specific notification settings
      const payload = {
        notification: {
          title: data.title || 'New Service Request',
          body: data.body || 'A new request is available in your area',
        },
        data: {
          ...(data.data || {}),
          click_action: 'FLUTTER_NOTIFICATION_CLICK', // Required for Android intent handling
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'service_requests', // Must match Flutter's channel
            sound: 'default',
            visibility: 'public'
          }
        },
        apns: {
          headers: {
            'apns-priority': '10', // iOS priority (10=immediate delivery)
            'apns-push-type': 'alert'
          },
          payload: {
            aps: {
              sound: 'default',
              contentAvailable: 1 // Enable background handling
            }
          }
        }
      };

      const batchSize = 500; // FCM's maximum per batch
      let totalSuccess = 0;
      let totalFailure = 0;

      for (let i = 0; i < data.tokens.length; i += batchSize) {
        const batchEnd = Math.min(i + batchSize, data.tokens.length);
        const batchTokens = data.tokens.slice(i, batchEnd);
        
        try {
          console.log(`Processing batch ${i}-${batchEnd}`);
          
          const response = await admin.messaging().sendMulticast({
            tokens: batchTokens,
            ...payload
          });

          console.log(`Batch ${i}-${batchEnd} results:`,
            `${response.successCount} successful,`,
            `${response.failureCount} failed`
          );

          totalSuccess += response.successCount;
          totalFailure += response.failureCount;

          // Handle failed tokens
          const failedTokens = [];
          response.responses.forEach((resp, index) => {
            if (!resp.success) {
              failedTokens.push({
                token: batchTokens[index],
                error: resp.error?.message || 'Unknown error'
              });
            }
          });

          if (failedTokens.length > 0) {
            console.log(`Marking ${failedTokens.length} tokens as inactive`);
            await cleanupFailedTokens(failedTokens.map(t => t.token));
          }

        } catch (err) {
          console.error(`Fatal error processing batch ${i}-${batchEnd}:`, err);
          // Don't rethrow to continue processing next batches
        }
      }

      console.log(`Total results: ${totalSuccess} successful, ${totalFailure} failed`);
      await snapshot.ref.delete();
      return;

    } catch (error) {
      console.error("Critical error in notification processing:", error);
      return;
    }
  }
);

async function cleanupFailedTokens(tokens) {
  const db = admin.firestore();
  const workersCollection = db.collection('workers_fcm');
  
  const chunkSize = 500; // Firestore batch limit
  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    const batch = db.batch();
    
    chunk.forEach(token => {
      const query = workersCollection.where('token', '==', token);
      batch.update(query, { active: false, lastError: 'Invalid token' });
    });

    try {
      await batch.commit();
      console.log(`Marked ${chunk.length} tokens as inactive`);
    } catch (err) {
      console.error("Error updating token status:", err);
    }
  }
}