import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    if (!record || !record.id) {
      return new Response(JSON.stringify({ error: "No record in payload" }), { status: 400 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: appt, error } = await supabase
      .from("appointments")
      .select("*, services(name), team_members(name), profiles(full_name, email)")
      .eq("id", record.id)
      .single();

    if (error || !appt) {
      return new Response(JSON.stringify({ error: "Appointment not found", details: error }), { status: 400 });
    }

    const toEmail = appt.profiles?.email;
    if (!toEmail) {
      return new Response(JSON.stringify({ error: "No recipient email" }), { status: 400 });
    }

    const html = `
      <div style="font-family:sans-serif;max-width:480px;margin:auto;">
        <h2 style="color:#2247E0;">Appointment Confirmed</h2>
        <p>Hi ${appt.profiles?.full_name || ""},</p>
        <p>Your appointment with PHCTM Library has been confirmed:</p>
        <table style="width:100%;border-collapse:collapse;">
          <tr><td style="padding:6px 0;color:#666;">Booking ID</td><td style="padding:6px 0;font-weight:bold;">${appt.booking_ref}</td></tr>
          <tr><td style="padding:6px 0;color:#666;">Service</td><td style="padding:6px 0;font-weight:bold;">${appt.services?.name || ""}</td></tr>
          <tr><td style="padding:6px 0;color:#666;">Officer</td><td style="padding:6px 0;font-weight:bold;">${appt.team_members?.name || ""}</td></tr>
          <tr><td style="padding:6px 0;color:#666;">Date</td><td style="padding:6px 0;font-weight:bold;">${appt.appointment_date}</td></tr>
          <tr><td style="padding:6px 0;color:#666;">Time</td><td style="padding:6px 0;font-weight:bold;">${appt.appointment_time}</td></tr>
          <tr><td style="padding:6px 0;color:#666;">Type</td><td style="padding:6px 0;font-weight:bold;">${appt.appointment_type}</td></tr>
        </table>
        <p style="margin-top:20px;color:#666;">— i-Connect @ PHCTM Library</p>
      </div>
    `;

    const resendResp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "i-Connect <onboarding@resend.dev>",
        to: toEmail,
        subject: `Appointment Confirmed — ${appt.booking_ref}`,
        html,
      }),
    });

    const resendData = await resendResp.json();

    if (!resendResp.ok) {
      return new Response(JSON.stringify({ error: "Resend failed", details: resendData }), { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true, resendData }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
