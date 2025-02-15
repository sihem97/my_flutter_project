const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Define an HTTPS function to handle incoming requests
exports.sendToWorkers = onRequest(async (req, res) => {
  // Ensure the request method is POST
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    // Parse the incoming JSON data
    const body = req.body;

    // Extract the required fields
    const {service, description, imageUrls, latitude, longitude} = body;

    // Validate the incoming data (optional but recommended)
    if (!service || !description || !latitude || !longitude) {
      return res.status(400).send("Bad Request: Missing required fields.");
    }

    // Log the received data for debugging purposes
    logger.info("Received request:", {
      service,
      description,
      imageUrls,
      latitude,
      longitude,
    });

    // Simulate sending data to workers (replace with actual logic)
    const responseMessage = {
      message: "Demande reçue avec succès!",
    };

    // Send a success response back to the client
    res.status(200).json(responseMessage);
  } catch (error) {
    // Handle errors and send an error response
    logger.error("Error processing request:", error);
    res.status(500).send("An error occurred while processing your request.");
  }
});
