var urlOrigin = window.location.origin;
var restapp = "/csp/irisapp"
var urlREST = `${urlOrigin}${restapp}/api`;

$(document).ajaxError(function (event, jqXHR, ajaxSettings, thrownError) {
  console.log(jqXHR.status, event, ajaxSettings, thrownError)
});

$(document).ready(function () {

  var lastStatus;
  var updateTimeout = 5;
  var getChartData = function() {
    $.getJSON(`${urlREST}/wordcloud`, function (response) {
      var msg = '';
      switch(response.loadingStatus) {
        case 'NO_DATA':
          msg = 'No ZPM data available. Data will be automatically updated soon.';
          $('#container-updating').removeClass('loadPending');
          break;
        case 'LOADING':
          msg = `Loading ZPM data... Updating every ${updateTimeout}s.`;
          $('#container-updating').addClass('loadPending');
          break;
        case 'DONE':
          msg = `ZPM data loaded (last update: ${response.lastUpdate})`;
          $('#container-updating').removeClass('loadPending');
          clearInterval(intervalId);
          break;
      }
      lastStatus = response.loadingStatus;
      $('#container-updating').text(msg);

      if (lastStatus !== 'NO_DATA') {
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
            data: response.data,
            name: 'tag count'
          }],
          title: {
            text: 'Tags on ZPM'
          }
        });
      }
    });
  
    if (lastStatus !== 'NO_DATA') {
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
            data: sankeyData.data,
            type: 'sankey',
            name: 'Module dependence on ZPM'
          }]
    
        });
      });
    }
  }
  
  var intervalId = setInterval(() => {
    getChartData();
  }, updateTimeout * 1000);
  getChartData();
});