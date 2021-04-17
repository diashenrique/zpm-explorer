var urlOrigin = window.location.origin;
var restapp = "/irisrad"
var urlREST = `${urlOrigin}${restapp}/form`;

$(document).ajaxError(function (event, jqXHR, ajaxSettings, thrownError) {
  console.log(jqXHR.status, event, ajaxSettings, thrownError)
  if (jqXHR.status === 401) {
    window.location.href = 'login.html';
  }
});

var qs = getQueryString();
var formName = qs.formName || 'dc.irisrad.default.UserForm';
var pIdSelected = "";

$(document).ready(function () {
  createMenu();

  $("#divProperties").hide();

  var storeSelectBox = new DevExpress.data.DataSource({
    store: new DevExpress.data.CustomStore({
      loadMode: "raw",
      load: function () {
        return $.getJSON(`${urlREST}/class/lookup`)
      }
    })
  });

  var toolbarCreateClass = $("#toolbar").dxToolbar({
    items: [{
      location: 'after',
      widget: 'dxButton',
      locateInMenu: 'auto',
      options: {
        icon: "plus",
        text: "New class",
        type: "default",
        onClick: function () {
          $("#divProperties").hide();
          form.resetValues();
          form.option("readOnly", false);
          selectSearch.option("value", "");
          dataGrid.option("dataSource", []);
          $("#btnSaveCompile").show();
          toolbarCreateClass.option("items[1].disabled", true);
        }
      }
    }, {
      location: 'after',
      widget: 'dxButton',
      locateInMenu: 'auto',
      disabled: true,
      options: {
        icon: "fas fa-cogs",
        text: "Compile",
        type: "default",
        elementAttr: {
          id: "btn-Compile"
        },
        onClick: function (e) {
          
          if (dataGrid.getVisibleRows().length == 0) {
            var result = DevExpress.ui.dialog.confirm("<i>Do you want to create a class with no properties?</i>", "Confirm changes");
            result.done(function(dialogResult) {
              if (dialogResult == true) {
                $.ajax({
                  url: `${urlREST}/class/compile/${encodeURIComponent(pIdSelected)}`,
                  method: "POST",
                  processData: false,
                  contentType: "application/json",
                  data: JSON.stringify(pIdSelected)
                }).done(function (e) {
                  DevExpress.ui.notify(e.msg, "success", 4000);
                });

              } 
            });
          }
        }
      }
    }, {
      location: 'after',
      widget: 'dxButton',
      locateInMenu: 'auto',
      options: {
        icon: "fas fa-trash",
        text: "Delete",
        type: "danger",
        onClick: function () {
          var dataForm = form.option("formData");

          if (jQuery.isEmptyObject(dataForm) == true) {
            DevExpress.ui.notify("No class selected", "error", 4000);
          } else {
            $.ajax({
              url: `${urlREST}/class/${encodeURIComponent(dataForm.ID)}`,
              method: "DELETE"
            }).done(function (returnDelete) {
              storeSelectBox.reload();
              $("#divProperties").hide();
              form.resetValues();
              form.option("readOnly", false);
              selectSearch.option("value", "");
              dataGrid.option("dataSource", []);
              DevExpress.ui.notify("Class " + returnDelete[0].ClassName + " has been deleted successfully", "info", 4000);
            });
          }

        }
      }
    }]
  }).dxToolbar("instance");

  var selectSearch = $("#select-class").dxSelectBox({
    dataSource: storeSelectBox,
    displayExpr: "ClassName",
    valueExpr: "ID",
    searchEnabled: true,
    onValueChanged: function (data) {
      pIdSelected = data.value;

      if (pIdSelected != "") {
        formDataValue(pIdSelected);
        form.option("readOnly", true);
        $("#divProperties").show();
        dataGrid.getDataSource().reload();
        $("#dataGridLine").dxDataGrid("instance").option("dataSource", createCustomStore);
        toolbarCreateClass.option("items[1].disabled", false);
      }
    }
  }).dxSelectBox("instance");

  $("#btnSaveCompile").dxButton({
    icon: "fas fa-save",
    type: "default",
    text: "Save",
    onClick: function (e) {
      if (!form.validate().isValid) {
        DevExpress.ui.notify("There are required fields not filled in", "error", 2000);
      } else {
        var dataForm = form.option("formData");

        toolbarCreateClass.option("items[1].disabled", false);

        console.log("save",dataForm);

        /*
        $("#btnSaveCompile").hide();

        $.ajax({
          url: `${urlREST}/class`,
          method: "POST",
          processData: false,
          contentType: "application/json",
          data: JSON.stringify(dataForm)
        }).done(function (retSaveClass) {
          storeSelectBox.reload();
          $("#select-class").dxSelectBox("instance").option("value", retSaveClass[0].ID);
          DevExpress.ui.notify("Class has been saved", "success", 4000);
        });

        $("#divProperties").show();
        */
      }
    }
  });

  var createCustomStore = new DevExpress.data.DataSource({
    store: new DevExpress.data.CustomStore({
      key: "ID",
      load: function () {
        return $.getJSON(`${urlREST}/class/fields/${encodeURIComponent(pIdSelected)}`, function (e) {
          console.log(e);
        });
      },
      insert: function (values) {
        values.ParentClass = pIdSelected;
        return $.ajax({
          url: `${urlREST}/class/fields`,
          method: "POST",
          processData: false,
          contentType: "application/json",
          data: JSON.stringify(values)
        });
      },
      update: function (key, values) {
        return $.ajax({
          url: `${urlREST}/class/fields/${encodeURIComponent(key)}`,
          method: "PUT",
          processData: false,
          contentType: "application/json",
          data: JSON.stringify(values)
        });
      },
      remove: function (key) {
        return $.ajax({
          url: `${urlREST}/class/fields/${encodeURIComponent(key)}`,
          method: "DELETE"
        });
      },
      onBeforeSend: function (method, ajaxOptions) {
        ajaxOptions.xhrFields = {
          withCredentials: true
        };
      }
    })
  });

  var dataGridConfig = {
    //dataSource: createCustomStore,
    dataSource: [],
    rowAlternationEnabled: true,
    allowColumnResizing: true,
    columnResizingMode: "widget",
    columnAutoWidth: true,
    showBorders: true,
    editing: {
      mode: "row",
      allowAdding: true,
      allowUpdating: true,
      allowDeleting: true
    },
    columns: [{
        dataField: "FieldName",
        width: 200
      },
      {
        dataField: "DisplayName",
        width: 200
      },
      {
        dataField: "FieldType",
        width: 200,
        lookup: {
          dataSource: fieldTypeSelectBox,
          displayExpr: "name",
          valueExpr: "id"
        }
      },
      {
        dataField: "IsRequired",
        caption: "Is Required?",
        dataType: "boolean",
        value: false,
      },
      {
        dataField: "ClassRelated",
        width: 300,
        lookup: {
          dataSource: storeSelectBoxRelatedClass,
          displayExpr: "name",
          valueExpr: "id"
        }
      }
    ],
    onEditorPrepared: function (options) {
      if (options.parentType === "dataRow" && options.dataField === "FieldType") {
        options.editorElement.dxSelectBox("instance").option("value", fieldTypeSelectBox[0].id);
      }
    }
  };
  dataGridConfig = addDefuaultGridErroHandler(dataGridConfig);
  var dataGrid = $("#dataGridLine").dxDataGrid(dataGridConfig).dxDataGrid("instance");
});

var storeSelectBoxRelatedClass = {
  store: new DevExpress.data.CustomStore({
    key: "id",
    loadMode: "raw",
    load: function () {
      return $.getJSON(`${urlREST}/class/relatedclass/lookup`)
    }
  }),
  sort: "name"
}

var storeSelectBoxExtendsClass = {
  store: new DevExpress.data.CustomStore({
    key: "id",
    loadMode: "raw",
    load: function () {
      return $.getJSON(`${urlREST}/class/relatedclass/extends`)
    }
  }),
  sort: "name"
}

var form = $("#formClassCreator").dxForm({
  //formData: "",
  colCount: 2,
  readOnly: false,
  showColonAfterLabel: false,
  labelLocation: "left",
  minColWidth: 300,
  items: [
  {
    dataField: "ClassName",
    editorOptions: {
      placeholder: "Enter class name - e.g. <Package>.<ClassName>"
    },
    validationRules: [{
      type: "required",
      message: "Class Name is required"
    }]
  },
  {
    dataField: "Description",
    editorOptions: {
      placeholder: "Enter class description to be used as Form Name"
    },
    validationRules: [{
      type: "required",
      message: "Description is required"
    }]
  }, 
  {
    dataField: "Extends",
    colSpan: 2,
    editorType: 'dxTagBox',
    editorOptions: {
      placeholder: "The classes that will give inheritance ...",
      dataSource: storeSelectBoxExtendsClass,
      valueExpr: "id",
      displayExpr: "name",
      openOnFieldClick: true,
      readOnly: false,
      searchEnabled: true,
      showClearButton: true
    }
  }
]
}).dxForm("instance");


function formDataValue(pId) {
  var retFormData = $.ajax({
    type: "GET",
    url: `${urlREST}/class/${encodeURIComponent(pId)}`,
    async: false,
    processData: false,
    contentType: "application/json",
    dataType: "json",
    done: function (results) {
      JSON.parse(results);
      console.log("done", results)
      return results;
    },
    fail: function (jqXHR, textStatus, errorThrown) {
      console.log('Could not get data, server response: ' + textStatus + ': ' + errorThrown);
    }
  }).responseJSON;
  form.option("formData", retFormData[0]);
};

var fieldTypeSelectBox = [{
    "id": "%Library.String",
    "name": "%Library.String"
  }, {
    "id": "%Library.BigInt",
    "name": "%Library.BigInt"
  },
  {
    "id": "%Library.Boolean",
    "name": "%Library.Boolean"
  },
  {
    "id": "%Library.Currency",
    "name": "%Library.Currency"
  },
  {
    "id": "%Library.Date",
    "name": "%Library.Date"
  },
  {
    "id": "%Library.DateTime",
    "name": "%Library.DateTime"
  },
  {
    "id": "%Library.Decimal",
    "name": "%Library.Decimal"
  },
  {
    "id": "%Library.Double",
    "name": "%Library.Double"
  },
  {
    "id": "%Library.Float",
    "name": "%Library.Float"
  },
  {
    "id": "%Library.Integer",
    "name": "%Library.Integer"
  },
  {
    "id": "%Library.Numeric",
    "name": "%Library.Numeric"
  },
  {
    "id": "%Library.PosixTime",
    "name": "%Library.PosixTime"
  },
  {
    "id": "%Library.SmallInt",
    "name": "%Library.SmallInt"
  },
  {
    "id": "%Library.Time",
    "name": "%Library.Time"
  },
  {
    "id": "%Library.TimeStamp",
    "name": "%Library.TimeStamp"
  },
  {
    "id": "%Library.TinyInt",
    "name": "%Library.TinyInt"
  },
  {
    "id": "%Library.VarString",
    "name": "%Library.VarString"
  },
  {
    "id": "Related",
    "name": "Related"
  },
  {
    "id": "Relationship",
    "name": "Relationship"
  }
]