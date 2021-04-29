var urlOrigin = window.location.origin;
var restapp = "/csp/irisapp"
var urlREST = `${urlOrigin}${restapp}/api`;

checkForUpdates();

$(document).ajaxError(function (event, jqXHR, ajaxSettings, thrownError) {
  console.log(jqXHR.status, event, ajaxSettings, thrownError)
});

function openDetails(repositoryLink) {
  window.open(repositoryLink, '_blank');
}

$(document).ready(function () {

  var selectedNamespace = null;

  var customStore = {
    store: new DevExpress.data.CustomStore({
      key: "name",
      loadMode: "raw",
      load: function () {
        return $.getJSON("https://pm.community.intersystems.com/packages/-/all")
      }
    }),
    sort: "name"
  }

  var selectboxNamespace = {
    store: new DevExpress.data.CustomStore({
      loadMode: "raw",
      load: function () {
        return $.getJSON(`${urlREST}/namespace`);
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
      mode: "single"
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
    selection: {
      mode: "single"
    },
    focusedRowEnabled: true,
    columns: ["name", "description",
      {
        dataField: "repository",
        cellTemplate: function (container, options) {
          var linkRepository = options.data.repository;
          container.append($("<a>").addClass('repoLink').text(linkRepository).on("click", function (args) {
            openDetails(linkRepository);
          }).appendTo(container));
        }
      },
      {
        dataField: "versions",
        caption: "Version",
        dataType: "string",
        alignment: "right",
        width: 100
      }
    ],
    onToolbarPreparing: function (e) {
      var dataGrid = e.component;

      e.toolbarOptions.items.push({
        location: "after",
        widget: "dxSelectBox",
        options: {
          dataSource: selectboxNamespace,
          placeholder: "Select Namespace to Install",
          valueExpr: "id",
          displayExpr: "text",
          width: 240,
          onValueChanged: function (data) {
              selectedNamespace = data.component.option('selectedItem');
          }
        }
      });

      e.toolbarOptions.items.push({
        location: "after",
        widget: "dxButton",
        options: {
          type: "default",
          icon: "fas fa-download",
          text: "Install",
          hint: "Install the selected package",
          onClick: function (e) {
            if (selectedNamespace === null) {
              DevExpress.ui.notify("No Namespace have been selected", "error");
            }

            var selectedRowsData = dataGrid.getSelectedRowsData();

            if (selectedRowsData.length === 0) {
              DevExpress.ui.notify("No package have been selected", "error");
            } else {
              var result = DevExpress.ui.dialog.confirm("Do you want to install the package <b>" + `${selectedRowsData[0].name}` + "</b> ?", "Install Package");
              result.done(function (resp) {
                if (resp) {
                  var values = {
                    name: selectedRowsData[0].name,
                    version: selectedRowsData[0].versions[0],
                    namespace: selectedNamespace.id
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
                    DevExpress.ui.notify(e.msg, e.status, 4000);
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