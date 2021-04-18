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
    rowAlternationEnabled: true,
    allowColumnResizing: true,
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
    columns: ["name","description",{
      dataField: "repository",
      cellTemplate: function (container, options) {
          var linkRepository = options.data.repository;
          container.append($("<a>").addClass('repoLink').text(linkRepository).on("click", function (args) {
              openDetails(linkRepository);
          }).appendTo(container));
      }
    }]
  });




});