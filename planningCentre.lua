local json = require("dkjson") 

-- create a client and secret id from your planning center dev account
local client_id = "" 
local secret = ""

local baseUrl = "https://api.planningcenteronline.com/services/v2"

local function FetchJson(url)
  local curl = string.format('curl -s -u "%s:%s" "%s"', client_id, secret, url)
  local handle = io.popen(curl)
  local result = handle:read("*a")
  handle:close()

  local obj, _, err = json.decode(result, 1, nil)
  if err then
    print("JSON decode error:", err)
    return nil
  end

  return obj
end

function GetServiceTypes()
  local url = baseUrl .. "/service_types"
  return FetchJson(url)
end

function GetPlans(service_type_id, future_only, include_series)
  local query = ""

  if future_only then
    query = "?filter=future"
  end

  if include_series then
    if query == "" then
      query = "?include=series"
    else
      query = query .. "&include=series"
    end
  end

  local path = string.format("/service_types/%s/plans%s", service_type_id, query)
  local url = baseUrl .. path

  return FetchJson(url)
end

function GetPlanOrder(service_type_id, plan_id)
  local path = string.format("/service_types/%s/plans/%s/items", service_type_id, plan_id)
  local url = baseUrl .. path

  return FetchJson(url)
end

function GetTeamMembers(service_type_id, plan_id)
  local path = string.format("/service_types/%s/plans/%s/team_members", service_type_id, plan_id)
  local url = baseUrl .. path

  return FetchJson(url)
end

function IndexOf(tbl, value)
  for i, v in ipairs(tbl) do
    if v == value then
      return i
    end
  end
  return nil 
end

function GetSongs(service_order)
  if service_order then
    print("- Songs ----------------------")
    for _, item in ipairs(service_order.data) do
      if item.attributes.item_type == "song" then 
        print("",item.attributes.title)
      end
    end
  end
end


function IsDateToday(dateString)
  local year, month, day = dateString:match("(%d+)-(%d+)-(%d+)")
  local now = os.date("!*t")
  return tonumber(year) == now.year and tonumber(month) == now.month and tonumber(day) == now.day
end

function GetTodaysPlan(services)
  local plan_today;
  local service_name_today;
  local service_id_today;

  for _, service_type in ipairs(services.data) do
    local service_name = service_type.attributes.name
    local service_id = service_type.id

    local plans = GetPlans(service_id, true, true)
    if plans then
      for _, plan in ipairs(plans.data) do
        local plan_date = plan.attributes.last_time_at
        
          if IsDateToday(plan_date) then
            plan_today = plan
            service_name_today = service_name
            service_id_today = service_id
          end
      end
    end
  end
  if plan_today then 
    print("------------------------------")
    print(service_name_today, plan_today.attributes.dates ) 
    -- print("Service id", service_id_today)
    -- print("Plan id", plan_today.id) -- debugging only!!!!!!!!!!!!!!!!!!
    GetSongs(GetPlanOrder(service_id_today, plan_today.id))
    print("------------------------------")
  else 
    print("No plans today")
  end
end

local function ProcessAll()
  local services = GetServiceTypes()
  if not services then return end
  GetTodaysPlan(services)
end

ProcessAll()
