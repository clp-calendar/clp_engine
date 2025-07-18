defmodule SDTCP.Handlers.Calendars do
  def dispatch("LIST", _json) do
    %{status: "ok", calendars: SD.Calendars.list_calendars()}
  end

  def dispatch("CREATE", json) do
    case Jason.decode(json) do
      {:ok, attrs} ->
        case SD.Calendars.create_calendar(attrs) do
          {:ok, cal} -> %{status: "ok", id: cal.id}
          {:error, cs} -> %{status: "error", errors: cs.errors}
        end

      _ ->
        %{status: "error", message: "invalid json"}
    end
  end

  def dispatch("GET", json) do
    case Jason.decode(json) do
      {:ok, %{"id" => id}} ->
        case SD.Calendars.get_calendar(id) do
          %SD.Calendars.Calendar{} = calendar ->
            %{status: "ok", calendar: %{"id" => calendar.id, "name" => calendar.name}}

          nil ->
            %{status: "error", message: "not found"}
        end

      _ ->
        %{status: "error", message: "invalid json"}
    end
  end

  def dispatch("UPDATE", json) do
    with {:ok, %{"id" => id} = attrs} <- Jason.decode(json),
         cal <- SD.Calendars.get_calendar(id),
         {:ok, updated} <- SD.Calendars.update_calendar(cal, attrs) do
      %{status: "ok", calendar: updated}
    else
      {:error, changeset} -> %{status: "error", errors: changeset.errors}
      _ -> %{status: "error", message: "invalid input or not found"}
    end
  end

  def dispatch("DELETE", json) do
    with {:ok, %{"id" => id}} <- Jason.decode(json),
         cal <- SD.Calendars.get_calendar(id),
         {:ok, _} <- SD.Calendars.delete_calendar(cal) do
      %{status: "ok"}
    else
      _ -> %{status: "error", message: "not found or failed to delete"}
    end
  end
end
