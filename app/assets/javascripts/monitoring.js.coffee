# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#class window.MonitoringSubmitter
#
#  constructor: () ->
#
#
#  submitButtonListener: () ->
#    $('')

class window.MonitoringChart

  constructor: (@metric_name, @monitoring_period_start, @monitoring_period_end, @time_resolution, @chart_label) ->
    console.log "Metric: #{@metric_name}"
    console.log "Start: #{@monitoring_period_start}"
    console.log "End: #{@monitoring_period_end}"
    console.log "Resolution: #{@time_resolution}"

  createChart: (@chart_label, chart_points) =>
    chart_label = @chart_label
    Highcharts.setOptions({
      global: {
        useUTC: false
      }
    })

    @chart = $(".container##{@metric_name}").highcharts({
      chart: {
        type: 'spline',
        animation: Highcharts.svg,
        marginRight: 10,
      },
      title: {
          text: @chart_label
      },
      xAxis: {
          type: 'datetime',
          tickPixelInterval: 150
      },
      yAxis: {
          title: {
              text: 'Value'
          },
          plotLines: [{
              value: 0,
              width: 1,
              color: '#808080'
          }]
      },
      tooltip: {
          formatter: () ->
            "<b>#{this.series.name}</b><br/>
             Measurement date: #{Highcharts.dateFormat('%Y-%m-%d %H:%M:%S', new Date(this.x))}<br/>
             #{chart_label}: #{this.y}"
      },
      legend: {
          enabled: false
      },
      exporting: {
          enabled: false
      },
      series: chart_points
    })

  startUpdating: (measurement_url, @hosts) =>
    console.log "Starting to monitor - #{measurement_url}"
    console.log @hosts
    @last_timestamp = new Date().getTime()
    console.log @last_timestamp

    setInterval () =>
      console.log "Update monitoring"
      current_timestamp = new Date().getTime()

      console.log "Getting monitoring data from #{Math.round(@last_timestamp / 1000)} to #{Math.round(current_timestamp / 1000)}"

      $.ajax(measurement_url, {
        data: {
          metric: @metric_name,
          hosts: @hosts,
          start_time: Math.round(@last_timestamp / 1000),
          end_time: Math.round(current_timestamp / 1000),
          time_resolution: @time_resolution
        },
        success: (data, status, xhr) =>
          console.log data
          chart = (i for i in Highcharts.charts when i.options.title.text is @chart_label)[0]
          if data.length > 0
            for metric_measurement in data
              console.log "Finding series with name #{metric_measurement.name}"
              series = (i for i in chart.series when i.name is metric_measurement.name)[0]
              console.log "Found series: #{series}"
              console.log series.data
              last_point = series.data[series.data.length - 1]
              last_point = [last_point.x, last_point.y]
              for point in metric_measurement.data
                console.log "adding point: #{last_point[0]} --- #{point[1]}"
                console.log "adding point: #{point[0]*1000} --- #{point[1]}"

                series.addPoint([ last_point[0], point[1] ])
                series.addPoint([ point[0]*1000, point[1] ])

                last_point = [ point[0]*1000, point[1] ]
            @last_timestamp = current_timestamp
      })
    ,
    @time_resolution * 1000
