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
      key: "name",
      loadMode: "raw",
      load: function () {
        return $.getJSON("https://pm.community.intersystems.com/packages/-/all")
      }
    }),
    sort: "name"
  }

  $("#package-list").dxDataGrid({
    dataSource: customStore,
    rowAlternationEnabled: false,
    columnResizingMode: "widget",
    //columnAutoWidth: true,
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
      allowedPageSizes: [10, 20, 30, 40, 50, 100],
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
    headerFilter: {
      visible: true
    },
    selection: {
      mode: "single"
    },
    focusedRowEnabled: true,
    columns: ["name", "description", {
      dataField: "repository",
      cellTemplate: function (container, options) {
        var linkRepository = options.data.repository;
        container.append($("<a>").addClass('repoLink').text(linkRepository).on("click", function (args) {
          openDetails(linkRepository);
        }).appendTo(container));
      }
    }],
    onSelectionChanged: function (selectedItems) {
      var data = selectedItems.selectedRowsData[0];
      if (data) {
        //console.log(data.name);
      }
    },
    onToolbarPreparing: function (e) {
      var dataGrid = e.component;

      e.toolbarOptions.items.push({
        location: "after",
        widget: "dxButton",
        options: {
          icon: "fas fa-download",
          text: "Install",
          hint: "Install the selected package",
          onClick: function (e) {

            var selectedRowsData = dataGrid.getSelectedRowsData();

            console.log(selectedRowsData.length);


            var idSelecionado = $("#selected-items-container").text();

            if (selectedRowsData.length === 0) {
              DevExpress.ui.notify("No package have been selected", "error");
            } else {
              var result = DevExpress.ui.dialog.confirm("Do you want to install the package <b>"+`${selectedRowsData[0].name}` + "</b> ?", "Install Package");
              result.done(function (resp) {
                if (resp) {
                  var values = {
                    id: idSelecionado,
                    namespace: selectedNamespace
                  };
                  $.ajax({
                    url: urlREST + "/message/resend/",
                    method: "POST",
                    processData: false,
                    contentType: "application/json",
                    data: JSON.stringify(values)
                  }).done(function () {
                    DevExpress.ui.notify("Messages were successfully resent", "success", 4000);
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