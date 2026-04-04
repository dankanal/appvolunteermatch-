const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { Resend } = require("resend");

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

exports.sendReportEmail = onDocumentCreated(
  {
    document: "reports/{reportId}",
    region: "us-central1",
    secrets: [RESEND_API_KEY],
  },
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) {
        logger.error("No snapshot data in event");
        return;
      }

      const data = snap.data() || {};
      const reportId = event.params.reportId;

      const resend = new Resend(RESEND_API_KEY.value());

      const type = String(data.type || "unknown");
      const reason = String(data.reason || "Без описания");
      const requestId = String(data.requestId || "");
      const chatId = String(data.chatId || "");
      const reportedUserId = String(data.reportedUserId || "");
      const createdBy = String(data.createdBy || "");
      const createdByEmail = String(data.createdByEmail || "");
      const status = String(data.status || "new");

      const html = `
        <div style="font-family:Arial,sans-serif;line-height:1.6">
          <h2>Новая жалоба в Volunteer Match</h2>
          <p><strong>Report ID:</strong> ${reportId}</p>
          <p><strong>Тип:</strong> ${type}</p>
          <p><strong>Статус:</strong> ${status}</p>
          <p><strong>Причина:</strong><br/>${escapeHtml(reason).replace(/\n/g, "<br/>")}</p>
          <hr/>
          <p><strong>Request ID:</strong> ${requestId || "-"}</p>
          <p><strong>Chat ID:</strong> ${chatId || "-"}</p>
          <p><strong>На кого жалоба (userId):</strong> ${reportedUserId || "-"}</p>
          <p><strong>Кто отправил (uid):</strong> ${createdBy || "-"}</p>
          <p><strong>Email отправителя:</strong> ${createdByEmail || "-"}</p>
        </div>
      `;

      const { data: emailResult, error } = await resend.emails.send({
        from: "Volunteer Match <onboarding@resend.dev>",
        to: ["volunteermatch1@gmail.com"],
        subject: `Новая жалоба [${type}] • ${reportId}`,
        html,
      });

      if (error) {
        logger.error("Resend send error", error);
        return;
      }

      logger.info("Report email sent", emailResult);
    } catch (e) {
      logger.error("sendReportEmail failed", e);
    }
  }
);

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}