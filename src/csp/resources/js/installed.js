var urlOrigin = window.location.origin;
var restapp = "/csp/irisapp"
var urlREST = `${urlOrigin}${restapp}/api`;

$(document).ajaxError(function (event, jqXHR, ajaxSettings, thrownError) {
  console.log(jqXHR.status, event, ajaxSettings, thrownError)
});

function openDetails(repositoryLink) {
  window.open(repositoryLink, '_blank');
}

$(document).ready(function () {
  var customStore = {
    store: new DevExpress.data.CustomStore({
      key: "id",
      loadMode: "raw",
      load: function () {
        return checkForUpdates().
        done(data => {
          return data.map(el => {
            el.updateAvailable = !isUpdated(el.currentVersion, el.version) ? 'Yes' : 'No';
            return el;
          });
        });
      }
    })
  }

  var loadPanel = $(".loadpanel").dxLoadPanel({
    message: 'ZPM is working...',
    shadingColor: "rgba(0,0,0,0.4)",
    visible: false,
    showIndicator: true,
    showPane: true,
    shading: true,
    closeOnOutsideClick: false
  }).dxLoadPanel("instance");

  var showLoadPanel = function () {
    loadPanel.show();
  };

  var moduleXML = '';

  $("#package-list").dxDataGrid({
    dataSource: customStore,
    rowAlternationEnabled: true,
    columnResizingMode: "widget",
    allowColumnResizing: true,
    showColumnLines: true,
    showRowLines: true,
    hoverStateEnabled: true,
    showBorders: true,
    paging: {
      pageSize: 10
    },
    pager: {
      showPageSizeSelector: true,
      allowedPageSizes: [5, 10, 20],
      showInfo: true
    },
    sorting: {
      mode: "multiple"
    },
    filterRow: {
      visible: true,
      applyFilter: "auto"
    },
    searchPanel: {
      visible: true,
      width: 240,
      placeholder: "Search..."
    },
    headerFilter: {
      visible: true
    },
    selection: {
      mode: "multiple"
    },
    onRowPrepared(e) {
      if (e.rowType == 'data' && !isUpdated(e.data.currentVersion, e.data.version)) {
        e.rowElement[0].style.fontWeight = 'bold';
      }
    },
    focusedRowEnabled: true,
    columns: [{
      dataField: "namespace",
      sortOrder: "asc"
    }, {
      dataField: "name",
      sortOrder: "asc"
    }, {
      dataField: "dateTimeInstallation",
      dataType: "datetime"
    }, {
      dataField: "version",
      caption: "Installed Version",
      dataType: "string",
      alignment: "right"
    }, {
      dataField: "currentVersion",
      dataType: "string",
      alignment: "right"
    }, {
      dataField: "updateAvailable",
      caption: "Update available?",
      dataType: "string",
      alignment: "center"
    }],
    onToolbarPreparing: function (e) {
      var dataGrid = e.component;

      e.toolbarOptions.items.push({
        location: "after",
        widget: "dxButton",
        options: {
          type: "default",
          icon: "fas fa-download",
          text: "Update",
          hint: "Update the selected package",
          onClick: function (e) {

            var selectedRowsData = dataGrid.getSelectedRowsData();

            if (selectedRowsData.length === 0) {
              DevExpress.ui.notify("No package have been selected.", "error");
            } else if (selectedRowsData.length > 1) {
              DevExpress.ui.notify("Please, update one application at the time.", "error");
            } else {
              if (selectedRowsData[0].version === selectedRowsData[0].currentVersion) {
                DevExpress.ui.notify("The application's already in the latest version. No need to update it.", "warning");
              } else {
                var result = DevExpress.ui.dialog.confirm("Do you want to install the package <b>" + `${selectedRowsData[0].name}` + "</b> ?", "Install Package");
                result.done(function (resp) {
                  if (resp) {
                    var values = {
                      name: selectedRowsData[0].name,
                      update: 1,
                      namespace: selectedRowsData[0].namespace
                    };
                    showLoadPanel();
                    $.ajax({
                      url: urlREST + "/package",
                      method: "POST",
                      processData: false,
                      contentType: "application/json",
                      data: JSON.stringify(values)
                    }).done(function (e) {
                      loadPanel.hide();
                      console.log(e);
                      DevExpress.ui.notify(e.msg, e.status, 4000);
                      $("#package-list").dxDataGrid("instance").refresh();
                    });
                  }
                });
              }
            }
          }
        }
      }, {
        location: "after",
        widget: "dxButton",
        options: {
          type: "default",
          icon: "fas fa-file-export",
          text: "Export",
          hint: "Export selected packages as dependencies for a new ZPM package",
          onClick: function (e) {
            var selectedRowsData = dataGrid.getSelectedRowsData();
            if (selectedRowsData.length === 0) {
              DevExpress.ui.notify("No package have been selected", "error");
            } else {
              const packages = {
                "dependencies": selectedRowsData.map(item => `${item.name}:${item.version}`).join()
              };
              console.log(packages)
              $.ajax({
                url: urlREST + "/export",
                method: "POST",
                processData: false,
                contentType: "application/json",
                data: JSON.stringify(packages)
              }).done(function (e) {
                // moduleXML = atob(e.module).replaceAll("<", "&#60;").replaceAll(">", "&#62;");
                moduleXML = _.escape(atob(e.module));
                var popupOptions = {
                  width: 800,
                  height: 550,
                  contentTemplate: function () {
                    return $("<div/>").append(
                      $(`<div style="width:100%; text-align:right"><a class="btn" href="#" onclick="copyToClipboard($('.xml')[0])"><i class="fas fa-copy"></i></a></div>`),
                      // $(`<textarea cols="110" rows="24">${moduleXML}</textarea>`)
                      $(`<pre style="height:400px; overflow-y:auto;"><code class="xml"></code></pre>`)
                    );
                  },
                  onContentReady: function () {
                    var el = document.querySelector('.xml');
                    el.innerHTML = moduleXML;
                    hljs.highlightBlock(el);
                  },
                  showTitle: true,
                  title: "module.xml",
                  dragEnabled: true,
                  closeOnOutsideClick: true
                };
                $("#popup").dxPopup(popupOptions).dxPopup("instance").show();
              });
            }
          }
        }
      }, {
        location: "after",
        widget: "dxButton",
        options: {
          type: "danger",
          icon: "fas fa-trash",
          text: "Uninstall",
          hint: "Uninstall the selected package",
          onClick: function (e) {

            var selectedRowsData = dataGrid.getSelectedRowsData();

            if (selectedRowsData.length === 0) {
              DevExpress.ui.notify("No package have been selected", "error");
            } else {
              const deletepackages = {
                "packages": selectedRowsData.map(item => `${item.id}`).join()
              };
              const deletepackagesMsg = {
                "packages": selectedRowsData.map(item => `[${item.namespace}]${item.name}`).join()
              };
              var result = DevExpress.ui.dialog.confirm("Do you want to <b>uninstall</b> the package(s) <b>" + `${deletepackagesMsg.packages}` + "</b> ?", "Install Package");
              result.done(function (resp) {
                if (resp) {
                  //showLoadPanel();
                  $.ajax({
                    url: `${urlREST}/package/delete`,
                    method: "POST",
                    processData: false,
                    contentType: "application/json",
                    data: JSON.stringify(deletepackages)
                  }).done(function (e) {
                    loadPanel.hide();
                    console.log(e);
                    DevExpress.ui.notify(e.msg, e.status, 4000);
                    $("#package-list").dxDataGrid("instance").refresh();
                  });
                }
              });
            }
          }
        }
      });
    },
  });
});

// https://stackoverflow.com/a/48020189/345422
var copyToClipboard = function (element) {
  var range = document.createRange();
  range.selectNode(element);
  window.getSelection().removeAllRanges(); // clear current selection
  window.getSelection().addRange(range); // to select text
  document.execCommand("copy");
  window.getSelection().removeAllRanges(); // to deselect
  DevExpress.ui.notify("Text has been copied to clipboard", "success", 4000);
}