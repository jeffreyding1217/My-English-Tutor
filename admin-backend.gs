// Bridge to China — admin dashboard backend.
// Paste this into Extensions > Apps Script on your Google Sheet,
// then follow APPS_SCRIPT_SETUP.md to deploy it as a Web app.

var ADMIN_TOKEN = "CHANGE_ME_TO_A_SECRET_PASSCODE";
var SHEET_NAME = "Submissions";

function getSheet_() {
  return SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
}

function jsonOut_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

// Listing submissions (admin dashboard only) — requires the token.
function doGet(e) {
  var token = e.parameter.token;
  if (token !== ADMIN_TOKEN) {
    return jsonOut_({ ok: false, error: "Unauthorized" });
  }
  var sheet = getSheet_();
  var data = sheet.getDataRange().getValues();
  var rows = data.slice(1).filter(function (r) { return r[0]; });
  var out = rows.map(function (r) {
    return { id: r[0], type: r[1], timestamp: r[2], status: r[3], summary: r[4], details: r[5] };
  });
  out.reverse(); // newest first
  return jsonOut_({ ok: true, submissions: out });
}

// Creating a new submission (public forms, no token needed) or
// updating a status (admin dashboard, token required).
function doPost(e) {
  var payload = JSON.parse(e.postData.contents);
  var sheet = getSheet_();

  if (payload.action === "update") {
    if (payload.token !== ADMIN_TOKEN) {
      return jsonOut_({ ok: false, error: "Unauthorized" });
    }
    var data = sheet.getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      if (String(data[i][0]) === String(payload.id)) {
        sheet.getRange(i + 1, 4).setValue(payload.status); // column D = Status
        return jsonOut_({ ok: true });
      }
    }
    return jsonOut_({ ok: false, error: "Not found" });
  }

  // Default action: create a new submission from a public form.
  var id = new Date().getTime() + "-" + Math.floor(Math.random() * 10000);
  sheet.appendRow([
    id,
    payload.type || "Unknown",
    new Date().toISOString(),
    "Pending",
    payload.summary || "",
    JSON.stringify(payload.details || {})
  ]);
  return jsonOut_({ ok: true, id: id });
}
