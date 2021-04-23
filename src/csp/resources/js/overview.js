var urlOrigin = window.location.origin;
var restapp = "/csp/irisapp"
var urlREST = `${urlOrigin}${restapp}/api`;

$(document).ajaxError(function (event, jqXHR, ajaxSettings, thrownError) {
  console.log(jqXHR.status, event, ajaxSettings, thrownError)
});

$(document).ready(function () {

  $.getJSON(`${urlREST}/wordcloud`, function (response) {
    Highcharts.chart('container-wordcloud', {
      accessibility: {
        screenReaderSection: {
          beforeChartFormat: '<h5>{chartTitle}</h5>' +
            '<div>{chartSubtitle}</div>' +
            '<div>{chartLongdesc}</div>' +
            '<div>{viewTableButton}</div>'
        }
      },
      series: [{
        type: 'wordcloud',
        data: response,
        name: 'tag count'
      }],
      title: {
        text: 'Tags on ZPM'
      }
    });
  });

  $.getJSON(`${urlREST}/sankey`, function (sankeyData) {
    Highcharts.chart('container-sankey', {
      chart: {
        inverted: true
      },
      title: {
        text: 'Module dependence on ZPM'
      },
      accessibility: {
        point: {
          valueDescriptionFormat: '{index}. {point.from} to {point.to}, {point.weight}.'
        }
      },
      plotOptions: {
        series: {
          dataLabels: {
            padding: 0,
            allowOverlap: false
          },
          nodePadding: 20
        }
      },
      series: [{
        keys: ['from', 'to', 'weight'],
        data: sankeyData,
        type: 'sankey',
        name: 'Module dependence on ZPM'
      }]

    });
  });
});