// Αυτόματο αντίγραφο ασφαλείας κοινοχρήστων στο Google Drive
// 1) script.google.com → Νέο έργο → επικόλληση όλου του κώδικα
// 2) Συμπλήρωσε τον κωδικό του χρήστη backup στο BACKUP_PASSWORD
// 3) Εκτέλεσε μία φορά τη συνάρτηση setup (δίνεις άδειες στο Drive)
//    → φτιάχνει φάκελο «Κοινόχρηστα – αντίγραφα» και ημερήσιο αντίγραφο κάθε βράδυ 03:00–04:00
const SUPABASE_URL = 'https://csjcqxulwspmmwfgenig.supabase.co';
const SUPABASE_KEY = 'sb_publishable_rbfYAfgoF1HHNUFwH9VcNw_oDbrAOkN';
const BACKUP_EMAIL = 'backup@polykatoikia.app';
const BACKUP_PASSWORD = 'ΒΑΛΕ-ΤΟΝ-ΚΩΔΙΚΟ';
const KEEP_DAYS = 90;            // πόσες μέρες κρατάμε αντίγραφα
const FOLDER = 'Κοινόχρηστα – αντίγραφα';
const EMAIL_TO = '';             // προαιρετικά: email (π.χ. Outlook) που θα παίρνει το αντίγραφο ως συνημμένο
const EMAIL_DAYS = [0];          // ποιες μέρες στέλνει email (0=Κυριακή … 6=Σάββατο)· [0,1,2,3,4,5,6] = κάθε μέρα

function setup() {
  ScriptApp.getProjectTriggers().forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger('dailyBackup').timeBased().everyDays(1).atHour(3).create();
  dailyBackup();
}

function dailyBackup() {
  const login = UrlFetchApp.fetch(SUPABASE_URL + '/auth/v1/token?grant_type=password', {
    method: 'post', contentType: 'application/json', headers: { apikey: SUPABASE_KEY },
    payload: JSON.stringify({ email: BACKUP_EMAIL, password: BACKUP_PASSWORD })
  });
  const token = JSON.parse(login.getContentText()).access_token;
  const res = UrlFetchApp.fetch(SUPABASE_URL + '/rest/v1/app_state?id=eq.1&select=data,updated_at', {
    headers: { apikey: SUPABASE_KEY, Authorization: 'Bearer ' + token }
  });
  const rows = JSON.parse(res.getContentText());
  if (!rows.length || !rows[0].data) throw new Error('Δεν βρέθηκαν δεδομένα');
  const folders = DriveApp.getFoldersByName(FOLDER);
  const folder = folders.hasNext() ? folders.next() : DriveApp.createFolder(FOLDER);
  const name = 'koinoxrista-' + Utilities.formatDate(new Date(), 'Europe/Athens', 'yyyy-MM-dd') + '.json';
  const blob = Utilities.newBlob(JSON.stringify(rows[0].data), 'application/json', name);
  folder.createFile(blob);
  if (EMAIL_TO && EMAIL_DAYS.indexOf(new Date().getDay()) >= 0)
    MailApp.sendEmail({ to: EMAIL_TO, subject: 'Αντίγραφο κοινοχρήστων ' + name.slice(12, 22), body: 'Συνημμένο το αντίγραφο ασφαλείας. Επαναφορά: Στοιχεία πολυκατοικίας → Επαναφορά.', attachments: [blob] });
  // σβήσιμο παλιών
  const limit = Date.now() - KEEP_DAYS * 86400000;
  const files = folder.getFiles();
  while (files.hasNext()) { const f = files.next(); if (f.getDateCreated().getTime() < limit) f.setTrashed(true); }
}
