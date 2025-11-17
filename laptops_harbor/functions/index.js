/**
firebase deploy --only functions
 * Import function triggers from their respective submodules
 */
const { setGlobalOptions } = require("firebase-functions");
const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");

// Initialize Firebase Admin (only if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Limit concurrent instances
setGlobalOptions({ maxInstances: 10 });

// 🔹 Nodemailer Gmail setup
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "samyaghaffar297@gmail.com",        // Replace with your Gmail
    pass: "qzaz wlgk irfn ivmi",        // Use Gmail App Password
  },
});

// Admin email for notifications
const ADMIN_EMAIL = "samyaghaffar297@gmail.com";

// 🔹 Helper function to escape HTML to prevent XSS
function escapeHtml(text) {
  if (!text) return "";
  const map = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;",
  };
  return String(text).replace(/[&<>"']/g, (m) => map[m]);
}

// 🔹 Helper function to get user data from Firebase Database
async function getUserData(userId) {
  try {
    const db = admin.database();
    const usersRef = db.ref("users");
    const snapshot = await usersRef
      .orderByChild("uuid")
      .equalTo(userId)
      .limitToFirst(1)
      .once("value");

    if (snapshot.exists() && snapshot.numChildren() > 0) {
      const userData = snapshot.val();
      const userKey = Object.keys(userData)[0];
      return userData[userKey];
    }
    return null;
  } catch (error) {
    logger.error("Error fetching user data:", error);
    return null;
  }
}

// 🔹 Order confirmation email function
exports.sendOrderConfirmation = functions.database
  .ref("/orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    const orderData = snapshot.val();
    const orderId = context.params.orderId;

    // Check if order has userId
    if (!orderData.userId) {
      logger.error(`Missing userId in order data for order ${orderId}`);
      return null;
    }

    // Fetch user data from Firebase Database
    const userData = await getUserData(orderData.userId);

    if (!userData) {
      logger.error(`User not found for userId: ${orderData.userId} in order ${orderId}`);
      return null;
    }

    if (!userData.email || !userData.username) {
      logger.error(`Missing email or username for user ${orderData.userId} in order ${orderId}`);
      return null;
    }

    const userEmail = userData.email;
    const userName = userData.username || "Customer";
    const orderTotal = orderData.totalAmount || orderData.total || orderData.amount || 0;
    const orderDate = new Date().toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });

    // Escape HTML to prevent XSS
    const safeUserName = escapeHtml(userName);
    const safeOrderId = escapeHtml(orderId);
    const safeOrderTotal = escapeHtml(orderTotal.toString());
    const safeOrderDate = escapeHtml(orderDate);

    // HTML email template for order confirmation
    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
            .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 5px 5px; }
            .order-info { background-color: white; padding: 15px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #4CAF50; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🎉 Order Confirmed!</h1>
            </div>
            <div class="content">
              <p>Hello <strong>${safeUserName}</strong>,</p>
              <p>Thank you for your order! We're excited to confirm that your order has been received and is being processed.</p>
              
              <div class="order-info">
                <h3>Order Details:</h3>
                <p><strong>Order ID:</strong> #${safeOrderId}</p>
                <p><strong>Order Date:</strong> ${safeOrderDate}</p>
                <p><strong>Total Amount:</strong> ₹${safeOrderTotal}</p>
              </div>
              
              <p>We'll send you another email once your order has been shipped. You can track your order status anytime from your account.</p>
              
              <p>If you have any questions, feel free to contact us. We're here to help!</p>
              
              <p>Best regards,<br><strong>Team Laptops Harbor</strong></p>
            </div>
            <div class="footer">
              <p>This is an automated email. Please do not reply to this message.</p>
            </div>
          </div>
        </body>
      </html>
    `;

    const mailOptions = {
      from: `"Laptops Harbor" <${transporter.options.auth.user}>`,
      to: userEmail,
      subject: `Order Confirmed - Order #${orderId} | Laptops Harbor`,
      text: `Hello ${userName},\n\nYour order #${orderId} has been confirmed!\n\nOrder Date: ${orderDate}\nTotal Amount: ₹${orderTotal}\n\nThank you for shopping with Laptops Harbor.\n\n- Team Laptops Harbor`,
      html: htmlContent,
    };

    try {
      await transporter.sendMail(mailOptions);
      logger.info(`✅ Order confirmation email sent successfully to ${userEmail} for order ${orderId}`);
    } catch (error) {
      logger.error(`❌ Error sending order confirmation email for order ${orderId}:`, error);
      // Don't throw error to prevent function retry loops
    }

    return null;
  });

// 🔹 Contact form email notification function
exports.sendContactFormEmail = functions.database
  .ref("/contacts/{contactId}")
  .onCreate(async (snapshot, context) => {
    const contactData = snapshot.val();
    const contactId = context.params.contactId;

    if (!contactData.email || !contactData.name) {
      logger.error(`Missing email or name in contact data for contact ${contactId}`);
      return null;
    }

    const contactDate = new Date(contactData.createdAt || Date.now()).toLocaleString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

    // Escape HTML to prevent XSS
    const safeName = escapeHtml(contactData.name);
    const safeEmail = escapeHtml(contactData.email);
    const safeSubject = escapeHtml(contactData.subject || "No subject");
    const safeMessage = escapeHtml(contactData.message || "").replace(/\n/g, "<br>");
    const safeContactId = escapeHtml(contactId);
    const safeContactDate = escapeHtml(contactDate);

    // 1. Send notification email to admin
    const adminHtmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
            .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 5px 5px; }
            .contact-info { background-color: white; padding: 15px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #2196F3; }
            .message-box { background-color: #e3f2fd; padding: 15px; margin: 15px 0; border-radius: 5px; border: 1px solid #90caf9; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>📧 New Contact Form Submission</h1>
            </div>
            <div class="content">
              <p>You have received a new contact form submission from your website.</p>
              
              <div class="contact-info">
                <h3>Contact Details:</h3>
                <p><strong>Name:</strong> ${safeName}</p>
                <p><strong>Email:</strong> <a href="mailto:${safeEmail}">${safeEmail}</a></p>
                <p><strong>Subject:</strong> ${safeSubject}</p>
                <p><strong>Submitted:</strong> ${safeContactDate}</p>
                <p><strong>Contact ID:</strong> ${safeContactId}</p>
              </div>
              
              <div class="message-box">
                <h3>Message:</h3>
                <p>${safeMessage}</p>
              </div>
              
              <p>Please respond to this inquiry at your earliest convenience.</p>
            </div>
          </div>
        </body>
      </html>
    `;

    const adminMailOptions = {
      from: `"Laptops Harbor Contact Form" <${transporter.options.auth.user}>`,
      to: ADMIN_EMAIL,
      subject: `New Contact Form: ${contactData.subject || "No Subject"} - ${contactData.name}`,
      text: `New Contact Form Submission\n\nName: ${contactData.name}\nEmail: ${contactData.email}\nSubject: ${contactData.subject || "No subject"}\n\nMessage:\n${contactData.message || ""}\n\nSubmitted: ${contactDate}\nContact ID: ${contactId}`,
      html: adminHtmlContent,
      replyTo: contactData.email, // So admin can reply directly
    };

    // 2. Send auto-reply email to user
    const userHtmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
            .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 5px 5px; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✅ Message Received!</h1>
            </div>
            <div class="content">
              <p>Hello <strong>${safeName}</strong>,</p>
              <p>Thank you for contacting Laptops Harbor! We have received your message and our team will get back to you as soon as possible.</p>
              
              <p><strong>Your Message:</strong></p>
              <p style="background-color: white; padding: 15px; border-radius: 5px; border-left: 4px solid #4CAF50;">
                ${safeMessage}
              </p>
              
              <p>We typically respond within 24-48 hours. If your inquiry is urgent, please feel free to call us directly.</p>
              
              <p>Best regards,<br><strong>Team Laptops Harbor</strong></p>
            </div>
            <div class="footer">
              <p>This is an automated confirmation email. Please do not reply to this message.</p>
            </div>
          </div>
        </body>
      </html>
    `;

    const userMailOptions = {
      from: `"Laptops Harbor" <${transporter.options.auth.user}>`,
      to: contactData.email,
      subject: "We've Received Your Message - Laptops Harbor",
      text: `Hello ${contactData.name},\n\nThank you for contacting Laptops Harbor! We have received your message and our team will get back to you as soon as possible.\n\nYour Message:\n${contactData.message || ""}\n\nWe typically respond within 24-48 hours.\n\nBest regards,\nTeam Laptops Harbor`,
      html: userHtmlContent,
    };

    try {
      // Send both emails
      await Promise.all([
        transporter.sendMail(adminMailOptions),
        transporter.sendMail(userMailOptions),
      ]);
      logger.info(`✅ Contact form emails sent successfully - Admin & User for contact ${contactId}`);
    } catch (error) {
      logger.error(`❌ Error sending contact form emails for contact ${contactId}:`, error);
      // Don't throw error to prevent function retry loops
    }

    return null;
  });

// You can keep your existing sample function
// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
