data = {}
request = undefined
s =
  version: 1
  first_year_of_responsibility: 1990

url_structure = [
  "version",
  "first_year_of_responsibility"
]

series = [
  'Before Budget'
  'Super-pessimistic'
  'Pessimistic'
  'Cautious'
  'Optimistic'
  'Super-optimistic'
  'Certain to be over'
]

update = () ->
  if request?
    setUrlToMatchSettings()
    request.abort()
  request = d3.tsv("/data#{urlForSettings()}", (error, d) ->
    return console.warn(error) if error
    d = series.map( (s) ->
      values = d.map( (d) ->
        # Turn it into x, y pairs
        { x: +d['Year'], y: +d[s] }
      ).filter( (d) ->
        # Remove pairs with zero values
        d.y > 0
      )
      # Jig the first value so inclusive of first year
      first = values[0]
      first.x -=1 if first?
      values
    )
    data = d
    window.data = d
    visualise()
  )

setUrlToMatchSettings = () ->
  history.pushState(undefined, undefined, urlForSettings())

window.onpopstate = () ->
  getSettingsFromUrl()
  updateControlsFromSettings()
  update()

urlForSettings = () ->
  url = for a in url_structure
    if s[a]?
      s[a]
    else
      ""
  "/" + url.join(':')

getSettingsFromUrl = () ->
  c = window.location.pathname.substring(1).split(':')

  for a,i in url_structure
    if c[i]? and c[i] != ""
      s[a] = c[i]



visualise = () ->
  
  margin =
    top: 40
    right:80 
    bottom: 40
    left: 80

  width = 1200
  height = 500

  unit = "MtCO2e/yr"

  xScale = d3.scale.linear()
    .domain([1749, 2102])
    .range([0, width - margin.left - margin.right])

  yScale = d3.scale.linear()
    .domain([0,1000])
    .range([height - margin.top - margin.bottom, 0])

  xAxis = d3.svg.axis().scale(xScale).orient("bottom").ticks(10).tickFormat(d3.format("d"))
  yAxis = d3.svg.axis().scale(yScale).orient("left").ticks(5)

  area = d3.svg.area()
    .x((d,i) -> xScale(d.x))
    .y0((d,i) -> yScale(0))
    .y1((d,i) -> yScale(d.y))

  # Select the svg element, if it exists.
  svg = d3.select('#chart').selectAll("svg")
    .data([data])
  
  # Otherwise, create the skeletal chart.
  gEnter = svg.enter()
    .append("svg")
    .append("g")
    .attr('class','drawing')

  # And the basic bits
  gEnter
    .append("g")
    .attr("class", "x axis")
  gEnter
    .append("g")
    .attr("class", "y axis")
  gEnter
    .append("text")
    .attr("class", "y axislabel")

  # Add the draggable fairness starts line
  drag = d3.behavior.drag()
    .on('drag', () ->
      t = d3.select(this)
      l = d3.select('.fair line')
      new_x = +t.attr('x') + d3.event.dx
      new_year = Math.round(xScale.invert(new_x))
      if new_year < 1752
        new_year = 1752
        new_x = xScale(1752)
      else if new_year > 2012
        new_year = 2012
        new_x = xScale(2012)

      s['first_year_of_responsibility'] = new_year

      t.attr('x', new_x)
      l.attr('x1',new_x)
      l.attr('x2',new_x)
      update()
    )

  fair = gEnter
    .append("g")
    .attr("class", 'fair')

  fair.append("line")
    .attr('y1',yScale(0))
    .attr('y2',yScale(1000))

  fair.append("text")
    .attr('y',yScale(1000))
    .call(drag)

  # Update the outer dimensions.
  svg
    .attr("width", width)
    .attr("height", height)

  # Update the inner dimensions.
  g = svg.select("g.drawing").attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  # Update the x-axis.
  g.select(".x.axis")
    .attr("transform", "translate(0," + yScale.range()[0] + ")")
    .call(xAxis)
   
  # Update the y-axis.
  g.select(".y.axis")
    .attr("transform", "translate(0," + xScale.range()[0] + ")")
    .call(yAxis)

  # Update the y-axis label.
  g.select(".y.axislabel")
    .attr("transform", "translate(0," + (xScale.range()[0] - 10) + ")")
    .text(unit)
  
  # Update the draggable area
  new_x = xScale(+s['first_year_of_responsibility'])
  g.select(".fair line")
    .attr('x1', new_x)
    .attr('x2', new_x)

  g.select(".fair text")
    .attr('x', new_x)
    .text("Taking into account emissions since #{s['first_year_of_responsibility']}")

  # Update the area paths
  areas = g.selectAll(".area")
    .data(Object)

  areas.enter()
    .append("path")
    .attr("class", (d,i) -> "area area#{i}")

  areas
    .attr("d", (d) -> area(d))


updateControlsFromSettings = () ->
  d3.selectAll('.control')
    .datum(() -> @dataset)
    .filter( (d) -> s[d.name]? )
    .property('value', (d) -> s[d.name])

getSettingsFromUrl()
updateControlsFromSettings()
update()
