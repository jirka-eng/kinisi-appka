/* Napojení na Supabase (EU). Publishable key je veřejný, data chrání Row Level Security v databázi
   (supabase/migrations/001_init.sql). Video se nikdy neodesílá, jen čísla ze souhrnu cvičení. */
(function(){
  const URL_ = "https://xpxapgwawwgxftawnqaw.supabase.co";
  const KEY = "sb_publishable_AjbDO_57pAcWRmNAZHLI8g_qlpmVFw8";
  const PAIR_KEY = "kinisi-pairing", QUEUE_KEY = "kinisi-upload-queue";

  const sb = window.supabase.createClient(URL_, KEY, {
    // Terapeut a pacient mají oddělené přihlášení, aby šly obě stránky zkoušet na jednom zařízení.
    auth: {persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: "implicit",
      storageKey: /terapeut/.test(location.pathname) ? "kinisi-auth-therapist" : "kinisi-auth-patient"}
  });
  const store = {
    get(k, d){ try{ return JSON.parse(localStorage.getItem(k)) ?? d; }catch(e){ return d; } },
    set(k, v){ try{ localStorage.setItem(k, JSON.stringify(v)); }catch(e){} }
  };
  const isAnon = s => !!s?.user?.is_anonymous;

  /* ---------- pacient ---------- */
  async function ensureAnon(){
    const {data: {session}} = await sb.auth.getSession();
    if(session) return session;
    const {data, error} = await sb.auth.signInAnonymously();
    if(error) throw error;
    return data.session;
  }
  // Pozvánka z odkazu ?pozvanka=KOD: telefon se přihlásí anonymně a spáruje s pacientem.
  async function pairFromUrl(){
    const u = new URL(location.href), code = u.searchParams.get("pozvanka");
    if(!code) return null;
    u.searchParams.delete("pozvanka"); history.replaceState(null, "", u.pathname + u.search + u.hash);
    try{ await ensureAnon(); }
    catch(e){ throw new Error("Spárování teď nejde (server nepovolil přihlášení telefonu). Dej vědět terapeutovi."); }
    const {data, error} = await sb.rpc("claim_invite", {p_code: code});
    if(error) throw new Error(/invalid invite/.test(error.message) ? "Pozvánka neplatí nebo už byla použita. Požádej terapeuta o novou." : "Spárování se nepovedlo: " + error.message);
    const row = Array.isArray(data) ? data[0] : data;
    const pairing = {patientId: row.patient_id, name: row.patient_name, at: new Date().toISOString()};
    store.set(PAIR_KEY, pairing);
    return pairing;
  }
  const getPairing = () => store.get(PAIR_KEY, null);

  function toRow(rec, patientId){
    return {patient_id: patientId, client_id: rec.id, exercise: rec.ex, primary_joint: rec.primary, started_at: rec.date,
      duration_s: rec.dur, reps: rec.reps, incomplete: rec.incomplete, good: rec.good, score: rec.score,
      best_range: rec.bestRange, errors: rec.errors || {}, pain: rec.pain, effort: rec.effort};
  }
  // Uloží souhrn cvičení na server; bez signálu ho podrží ve frontě a pošle příště.
  async function uploadSession(rec){
    const p = getPairing(); if(!p) return {ok: false, reason: "unpaired"};
    const q = store.get(QUEUE_KEY, {}); q[rec.id] = toRow(rec, p.patientId); store.set(QUEUE_KEY, q);
    return flushQueue();
  }
  async function flushQueue(){
    const q = store.get(QUEUE_KEY, {}), rows = Object.values(q);
    if(!rows.length) return {ok: true, sent: 0};
    try{
      await ensureAnon();
      const {error} = await sb.from("sessions").upsert(rows, {onConflict: "patient_id,client_id"});
      if(error) throw error;
      const left = store.get(QUEUE_KEY, {}); for(const r of rows) if(JSON.stringify(left[r.client_id]) === JSON.stringify(r)) delete left[r.client_id];
      store.set(QUEUE_KEY, left);
      return {ok: true, sent: rows.length};
    }catch(e){ return {ok: false, reason: e.message || String(e), pending: rows.length}; }
  }

  /* ---------- terapeut ---------- */
  async function therapistSession(){
    const {data: {session}} = await sb.auth.getSession();
    return session && !isAnon(session) ? session : null;
  }
  async function signIn(email){
    const redirect = location.origin + location.pathname;
    const {error} = await sb.auth.signInWithOtp({email, options: {emailRedirectTo: redirect, shouldCreateUser: true}});
    if(error) throw error;
  }
  const signOut = () => sb.auth.signOut();
  async function loadTherapistData(){
    const [p, s] = await Promise.all([
      sb.from("patients").select("id,name,user_id,invite_code,invite_expires,created_at").order("name"),
      sb.from("sessions").select("*").order("started_at")
    ]);
    if(p.error) throw p.error; if(s.error) throw s.error;
    return {patients: p.data, sessions: s.data};
  }
  async function addPatient(name){
    const {data, error} = await sb.from("patients").insert({name}).select().single();
    if(error) throw error; return data;
  }
  async function createInvite(patientId){
    const {data, error} = await sb.rpc("create_invite", {p_patient: patientId});
    if(error) throw error; return data;
  }
  async function deletePatient(id){ const {error} = await sb.from("patients").delete().eq("id", id); if(error) throw error; }
  function onSessionsChange(cb){
    return sb.channel("sessions-live").on("postgres_changes", {event: "*", schema: "public", table: "sessions"}, cb).subscribe();
  }
  const inviteLink = code => new URL("./?pozvanka=" + encodeURIComponent(code), location.href).href;

  window.KinisiAPI = {sb, pairFromUrl, getPairing, uploadSession, flushQueue,
    therapistSession, signIn, signOut, loadTherapistData, addPatient, createInvite, deletePatient, onSessionsChange, inviteLink,
    onAuth: cb => sb.auth.onAuthStateChange((ev, s) => cb(ev, s))};
})();
