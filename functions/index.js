const { onRequest, onCall } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const geofirestore = require('geofirestore');

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const GeoFirestore = geofirestore.initializeApp(db);
const geocollection = GeoFirestore.collection('workers_location');

// Calculate distance between two points using the Haversine formula
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * 
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function toRad(value) {
    return value * Math.PI / 180;
}

// Split array into chunks for batch processing
function chunkArray(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
        chunks.push(array.slice(i, i + size));
    }
    return chunks;
}

// HTTP endpoint for sending individual notifications
exports.sendNotificationToWorker = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  try {
    const { token, title, body, data } = req.body;

    if (!token || !title || !body) {
      res.status(400).send('Missing required parameters');
      return;
    }

    const message = {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        screen: 'worker_home',
        type: 'new_request',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'service_requests',
          priority: 'max', // Changed from 'high' to 'max'
          sound: 'default',
          visibility: 'public',
          importance: 'max', // Changed from 'high' to 'max'
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert' // Added push type
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    res.json({ success: true, messageId: response });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Triggered when a new service request is created
exports.onNewServiceRequest = onDocumentCreated('requests/{requestId}', async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log('No data associated with the event');
        return;
    }
    
    const request = snapshot.data();
    const requestId = event.params.requestId;
    
    // Validate request data
    if (!request.location || !request.service) {
        console.error('Invalid request data:', request);
        return null;
    }

    const { lat, lng } = request.location;
    const service = request.service;
    const radius = request.searchRadius || 10; // Default 10km if not specified
    const description = request.description || 'New service request';

    try {
        // Query for nearby workers using GeoFirestore
        const query = geocollection.near({ 
            center: new admin.firestore.GeoPoint(lat, lng),
            radius: radius // kilometers
        }).where('service', '==', service);

        const snapshot = await query.get();
        const notifications = [];
        
        snapshot.docs.forEach(doc => {
            const workerData = doc.data();
            if (workerData.fcmToken) {
                // Calculate actual distance
                const distance = calculateDistance(
                    lat,
                    lng,
                    workerData.position.geopoint.latitude,
                    workerData.position.geopoint.longitude
                );

                // Prepare notification for each worker
                notifications.push({
                    token: workerData.fcmToken,
                    notification: {
                        title: `New ${service} Request`,
                        body: `${description} (${distance.toFixed(1)}km away)`,
                    },
                    data: {
                        requestId: requestId,
                        distance: distance.toString(),
                        service: service,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        timestamp: new Date().toISOString(),
                    },
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'service_requests',
                            priority: 'high',
                            defaultSound: true,
                        },
                    },
                    apns: {
                        payload: {
                            aps: {
                                sound: 'default',
                            },
                        },
                    },
                });
            }
        });

        // Send notifications in batches of 500 (FCM limit)
        const chunks = chunkArray(notifications, 500);
        const sendPromises = chunks.map(chunk => 
            admin.messaging().sendAll(chunk)
        );

        const results = await Promise.all(sendPromises);
        
        // Log results
        const totalSent = results.reduce((acc, result) => 
            acc + result.successCount, 0);
        const totalFailed = results.reduce((acc, result) => 
            acc + result.failureCount, 0);

        console.log(`Successfully sent ${totalSent} notifications, ${totalFailed} failed`);

        // Update request document with notification status
        await snapshot.ref.update({
            notificationsSent: {
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                totalSent,
                totalFailed,
            }
        });
        
        return { success: true, notificationsSent: totalSent, notificationsFailed: totalFailed };

    } catch (error) {
        console.error('Error processing request:', error);
        
        // Update request document with error status
        await snapshot.ref.update({
            notificationError: {
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                error: error.message
            }
        });

        throw new Error('Failed to process service request');
    }
});

// Cleanup function to remove old tokens
exports.cleanupInactiveWorkers = onSchedule('every 24 hours', async (context) => {
    try {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const snapshot = await db.collection('workers_location')
            .where('lastUpdated', '<', thirtyDaysAgo)
            .get();

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`Cleaned up ${snapshot.size} inactive worker locations`);
        
        return { cleaned: snapshot.size };
    } catch (error) {
        console.error('Error cleaning up inactive workers:', error);
        throw new Error('Cleanup failed');
    }
});

// Function to update worker location
// Update the updateWorkerLocation function
exports.updateWorkerLocation = onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
      throw new Error('User must be authenticated');
  }

  const { latitude, longitude, fcmToken, service } = data;

  if (!latitude || !longitude || !fcmToken || !service) {
      throw new Error('Missing required fields');
  }

  try {
      // Create a batch write
      const batch = db.batch();
      const userRef = db.collection('users').doc(context.auth.uid);
      const workerLocationRef = geocollection.doc(context.auth.uid);

      // Update worker_location document
      batch.set(workerLocationRef, {
          position: new admin.firestore.GeoPoint(latitude, longitude),
          coordinates: {
              latitude: latitude,
              longitude: longitude,
          },
          fcmToken: fcmToken,
          service: service,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Update users document
      batch.update(userRef, {
          fcmToken: fcmToken,
          lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp()
      });

      // Commit the batch
      await batch.commit();

      console.log(`Successfully updated location and token for worker: ${context.auth.uid}`);
      return { success: true };
  } catch (error) {
      console.error('Error updating worker location:', error);
      throw new Error('Failed to update location');
  }
});