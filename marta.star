
load("render.star", "render")
load("http.star", "http")
load("math.star", "math")
load("cache.star", "cache")
load("encoding/json.star", "json")

MARTA_API = "http://developer.itsmarta.com/RealtimeTrain/RestServiceNextTrain/GetRealtimeArrivals"

STATION = "MIDTOWN STATION"

def main(config):
  predictions_cached = cache.get("marta_predictions")
  if predictions_cached != None:
    predictions = json.decode(predictions_cached)
  else:
    response = http.get(MARTA_API)
    if response.status_code != 200:
      fail("MARTA Train API request failed with status %d", response.status_code)
    predictions = response.json()
    cache.set("marta_predictions", json.encode(predictions), ttl_seconds=10)

  count = 0
  station_predictions = []
  rows = []

  for prediction in predictions:
    if prediction["STATION"] == STATION:
      station_predictions.append(prediction)
      count = count + 1

  sorted_predictions = sorted(station_predictions, key=sortFunc)

  for prediction in sorted_predictions:
      dest = getDestination(prediction["DESTINATION"])
      time = math.floor(int(prediction["WAITING_SECONDS"]) / 60)
      if time == 0: time = "Arr"
      else: time = str(time)
      rows.append(render.Stack(
        children=[
          render.Row(
            children = [
              render.Box(width = 1, height = 1, color = "#000"),
              render.Column(
                children = [
                  render.Box(width = 1, height = 1, color = "#000"),
                  render.Box(width = 3, height = 6, color = getLineColor(prediction["LINE"]))
                ]
              ),
              render.Box(width = 1, height = 1, color = "#000"),
              render.Text(dest, font = "tb-8"),
            ]
          ),
          render.Row(
            expanded=True,
            main_align="end",
            children = [
              render.Text(time, font = "tb-8", color = "#CCF")
            ]
          )
        ]
      ))

  return render.Root(
    render.Column(
      children = rows
    )
  )

def getLineColor(line):
  if line == "RED": return "#F00"
  if line == "GOLD": return "#FF0"
  if line == "BLUE": return "#00F"
  if line == "GREEN": return "#080"
  return "#000" 

def getDestination(dest):
  if dest == "North Springs": return "N Springs"
  if dest == "Hamilton E Holmes": return "HE Holmes"
  if dest == "Indian Creek": return "Indian Cr"
  if dest == "Edgewood Candler Park": return "E'wood/CP"
  return dest

def sortFunc(prediction):
  return int(prediction["WAITING_SECONDS"])