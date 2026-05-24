/**
 * index.js — Desert App Cloud Functions
 */

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const axios = require("axios");

initializeApp();

const db = getFirestore();

// WhatsApp server URL
const WHATSAPP_SERVER = "https://suhail-whatsapp-production.up.railway.app";

// WhatsApp API key — set via Firebase secret: WHATSAPP_API_KEY
const WHATSAPP_API_KEY = process.env.WHATSAPP_API_KEY;

// 35 minutes without any Firebase upload
const NO_RECENT_UPLOAD_LIMIT = 35 * 60;

// Debounce duration — wait 2 minutes after last upload before sending updated alert
const DEBOUNCE_SECONDS = 2 * 60;

// Max updated alert groups before auto-completing the trip
const MAX_UPDATED_ALERTS = 3;

// MARK: - Scheduled Trigger
exports.checkOverdueTrips = onSchedule({
    schedule: "every 5 minutes",
    secrets: ["WHATSAPP_API_KEY"]
}, async () => {
    const now = Date.now() / 1000;

    const snapshot = await db
        .collection("trips")
        .where("b-status", "in", ["active", "overdue"])
        .get();

    for (const doc of snapshot.docs) {
        const trip = doc.data();
        const tripId = doc.id;

        const status = trip["b-status"];
        const tripInfo = trip["e-tripInfo"] ?? {};
        const location = trip["c-lastKnownLocation"] ?? {};
        const alertStatus = trip["h-alertStatus"] ?? {};

        const returnTime = tripInfo.returnTime;
        const lastUploadTime = location.lastUploadTime ?? 0;

        if (!returnTime) continue;

        const returnTimePassed = now >= returnTime;
        const noRecentUploadFor35Min =
            lastUploadTime === 0 ||
            now - lastUploadTime >= NO_RECENT_UPLOAD_LIMIT;

        const alertAlreadySent = alertStatus.alertSent === true;

        // Step 1: Mark trip as overdue immediately when return time passes
        if (returnTimePassed && status !== "overdue") {
            await db.collection("trips").doc(tripId).update({
                "b-status": "overdue"
            });
            console.log(`Trip marked as overdue: ${tripId}`);
        }

        // Step 2: Send initial alert only if no recent upload for 35 minutes
        if (returnTimePassed && noRecentUploadFor35Min && !alertAlreadySent) {
            const alertSentSuccessfully = await sendAlert({
                tripId,
                trip,
                type: "initial"
            });

            if (!alertSentSuccessfully) {
                console.log(`Initial alert not marked as sent for ${tripId}`);
                continue;
            }

            await db.collection("trips").doc(tripId).update({
                "h-alertStatus": {
                    alertSent: true,
                    alertSentAt: now,
                    alertSentAtReadable: new Date().toLocaleString("ar-SA"),
                    updatedAlertCount: 0,
                    pendingAlertAt: 0,
                    reason: "return_time_passed_no_recent_upload"
                }
            });

            console.log(`Initial overdue alert sent for ${tripId}`);
        }

        // Step 3: Send debounced updated alert
        const pendingAlertAt = alertStatus.pendingAlertAt ?? 0;
        const hasPendingAlert = pendingAlertAt > 0;
        const debounceElapsed = now - pendingAlertAt >= DEBOUNCE_SECONDS;
        const currentCount = alertStatus.updatedAlertCount ?? 0;
        const maxReached = currentCount >= MAX_UPDATED_ALERTS;

        if (alertAlreadySent && hasPendingAlert && debounceElapsed && !maxReached) {
            const newCount = currentCount + 1;
            const shouldCompleteTrip = newCount >= MAX_UPDATED_ALERTS;

            const latestDoc = await db.collection("trips").doc(tripId).get();
            const latestTrip = latestDoc.data();

            const alertSentSuccessfully = await sendAlert({
                tripId,
                trip: latestTrip,
                type: "updated"
            });

            if (!alertSentSuccessfully) {
                console.log(`Updated alert failed for ${tripId}`);
                continue;
            }

            const updates = {
                "h-alertStatus.updatedAlertCount": newCount,
                "h-alertStatus.pendingAlertAt": 0,
                "h-alertStatus.updatedAlertSentAt": now,
                "h-alertStatus.updatedAlertSentAtReadable": new Date().toLocaleString("ar-SA")
            };

            if (shouldCompleteTrip) {
                updates["b-status"] = "completed";
                console.log(`Trip auto-completed after ${MAX_UPDATED_ALERTS} updated alert groups — ${tripId}`);
            } else {
                console.log(`Updated alert #${newCount} sent for ${tripId}`);
            }

            await db.collection("trips").doc(tripId).update(updates);
        }
    }
});

// MARK: - Location Update Trigger
exports.onLocationUpdatedAfterOverdue = onDocumentUpdated({
    document: "trips/{tripId}",
    secrets: ["WHATSAPP_API_KEY"]
}, async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const tripId = event.params.tripId;

    const beforeLocation = before["c-lastKnownLocation"] ?? {};
    const afterLocation = after["c-lastKnownLocation"] ?? {};
    const alertStatus = after["h-alertStatus"] ?? {};
    const status = after["b-status"];

    const oldUploadTime = beforeLocation.lastUploadTime ?? 0;
    const newUploadTime = afterLocation.lastUploadTime ?? 0;
    const newUploadArrived = newUploadTime > oldUploadTime;

    if (status !== "overdue") return;
    if (!newUploadArrived) return;
    if (alertStatus.alertSent !== true) return;

    const currentCount = alertStatus.updatedAlertCount ?? 0;
    if (currentCount >= MAX_UPDATED_ALERTS) return;

    const now = Date.now() / 1000;

    await db.collection("trips").doc(tripId).update({
        "h-alertStatus.pendingAlertAt": now
    });

    console.log(`Pending alert set for ${tripId} — will send after ${DEBOUNCE_SECONDS}s debounce`);
});

// MARK: - Send Alert Helper
async function sendAlert({ tripId, trip, type }) {
    const tripInfo = trip["e-tripInfo"] ?? {};
    const userInfo = trip["c-userInfo"] ?? {};
    const contacts = trip["d-emergencyContacts"] ?? [];
    const location = trip["c-lastKnownLocation"] ?? {};

    if (contacts.length === 0) {
        console.log(`No emergency contacts for ${tripId}`);
        return false;
    }

    const lat = location.lat;
    const lng = location.lng;

    if (!lat || !lng || lat === "Unknown" || lng === "Unknown") {
        console.log(`No location available for ${tripId}, alert not sent`);
        return false;
    }

    const userName = userInfo.userName ?? "المستخدم";
    const tripStartTime = tripInfo.startTimeReadable ?? "غير معروف";
    const returnTime = tripInfo.returnTimeReadable ?? "غير معروف";
    const lastUpload = location.lastUploadTimeReadable ?? "غير معروف";

    const mapsLink = `https://maps.google.com/?q=${lat},${lng}`;
    const tripLink = `https://suhail-1.web.app/?id=${tripId}`;

    const batteryLevel = location.deviceBatteryLevel;
    const batteryLine = (batteryLevel != null && batteryLevel >= 0)
        ? `\nنسبة البطارية:\n${batteryLevel}%`
        : "";

    const message = type === "updated"
        ? `السلام عليكم،

وصلنا تحديث جديد لموقع ${userName} بعد تنبيه عدم العودة السابق.

الموقع الحالي:
${mapsLink}

تفاصيل الرحلة كاملة:
${tripLink}

آخر تحديث للموقع:
${lastUpload}${batteryLine}

— تطبيق سهيل`
        : `السلام عليكم،

ما وصلنا أي تحديث لموقع ${userName} بعد وقت العودة المتوقع. الرحلة بدأت الساعة ${tripStartTime} وكان المفروض تنتهي الساعة ${returnTime}.

آخر موقع معروف:
${mapsLink}

تفاصيل الرحلة كاملة:
${tripLink}

آخر تحديث للموقع:
${lastUpload}${batteryLine}

نعرف إن الموقف ممكن يسبب قلق، لذلك ننصح بمحاولة التواصل معه مباشرة. وإذا ما قدرتوا توصلون له، نرجو التواصل مع الجهات المختصة أو مع دعم إنجاد على الرقم:
920018911

— تطبيق سهيل`;

    let sentToAtLeastOneContact = false;

    for (const contact of contacts) {
        const contactPhone = contact.phone?.replace(/\D/g, "");
        if (!contactPhone) continue;

        try {
            const response = await axios.post(`${WHATSAPP_SERVER}/send`, {
                phone: contactPhone,
                message
            }, {
                headers: { "x-api-key": WHATSAPP_API_KEY }
            });

            if (response.data?.success === true) {
                sentToAtLeastOneContact = true;
                console.log(`WhatsApp sent to ${contactPhone} for trip ${tripId}`);
            } else {
                console.error(`WhatsApp failed for ${contactPhone}:`, response.data);
            }
        } catch (err) {
            console.error(`Failed to send WhatsApp to ${contactPhone}:`, err.message);
        }
    }

    return sentToAtLeastOneContact;
}
