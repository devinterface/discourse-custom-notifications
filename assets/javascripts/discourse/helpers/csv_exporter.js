// import { registerHelper } from "discourse-common/lib/helpers";
// import { _addBulkButton } from "discourse/components/modal/topic-bulk-actions";
import { addBulkDropdownButton } from "discourse/components/bulk-select-topics-dropdown";
// questo import è dalla versione 3.3.2

addBulkDropdownButton({
  id: "button-export-csv",
  label: "custom.export_topic_csv",
  icon: "file",
  class: "btn-default",
  visible: ({ currentUser }) => true,
  action({ topics }) {
    let topics_id = [];
    for (let i = 0; i < topics.length; i++) {
      topics_id.push(topics[i].id);
    }
    $.ajax({
      type: "POST",
      url: "/download_csv_topics",
      data: { topics_id: topics_id },
      xhrFields: {
        responseType: "blob", // Specifica che la risposta è un file blob
      },
      success: function (blob, status, xhr) {
        // Ottieni il nome del file dall'header Content-Disposition
        const disposition = xhr.getResponseHeader("Content-Disposition");
        const filename = disposition
          ? disposition.match(/filename="(.+)"/)[1]
          : "download.csv";

        // Crea un URL per il file blob e avvia il download
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      },
      error: function (xhr) {
        console.error("Errore durante il download del CSV", xhr);
      },
    });
  },
});

// registerHelper("check-moderatori", checkModeratori);

// export default function checkModeratori(args) {
//   let groups = args[0];
//   for (let i = 0; i < groups.length; i++) {
//     if (groups[i]["name"] == "Moderatori") {
//       return true;
//     }
//   }
//   return false;
// }
