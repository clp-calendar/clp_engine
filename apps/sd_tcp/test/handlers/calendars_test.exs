defmodule SDTCP.Handlers.CalendarsTest do
  use SDTCP.DataCase, async: false
  import SD.CalendarsFixtures
  import SD.AccountsFixtures
  import SDTCP.TestHelper

  describe "calendars" do
    setup do
      account = authorized_account_fixture()

      %{account: account}
    end

    test "list all calendars" do
      account_id = account_fixture().id
      calendar_fixture(%{name: "One", account_id: account_id})
      calendar_fixture(%{name: "Two", account_id: account_id})

      authorize(%{})

      response = sd_send("CALENDARS.LIST|" <> Jason.encode!(authorize(%{})))

      assert response["status"] == "ok"
      assert length(response["calendars"]) >= 2
    end

    test "CALENDARS.CREATE creates a new calendar with just a title" do
      tenant = SD.TenantsFixtures.tenant_fixture()
      payload = %{"name" => "RubyConf", "tenant_id" => tenant.id} |> authorize()
      raw = "CALENDARS.CREATE|#{Jason.encode!(payload)}"
      response = sd_send(raw)

      assert %{
               "status" => "ok",
               "calendar" => %{
                 "color_theme" => nil,
                 "id" => id,
                 "name" => "RubyConf",
                 "tenant_id" => tenant_id,
                 "visibility" => "public"
               }
             } = response

      assert is_binary(id)
      assert tenant_id == tenant.id
    end

    test "fetch calendar by id" do
      calendar = calendar_fixture(%{name: "Fetch Me"})

      payload = %{"id" => calendar.id} |> authorize()
      get_resp = sd_send("CALENDARS.GET|" <> Jason.encode!(payload))

      assert get_resp["status"] == "ok"
      assert get_resp["calendar"]["name"] == "Fetch Me"
    end

    test "fetch calendar with invalid id returns error" do
      payload = %{"id" => "00000000-0000-0000-0000-000000000000"} |> authorize()

      response = sd_send("CALENDARS.GET|" <> Jason.encode!(payload))

      assert response["status"] == "error"
      assert response["message"] == "not found"
    end

    test "update calendar name" do
      calendar = calendar_fixture(%{name: "Old Name"})

      payload =
        %{
          "id" => calendar.id,
          "name" => "New Name"
        }
        |> authorize()

      response = sd_send("CALENDARS.UPDATE|" <> Jason.encode!(payload))

      assert %{
               "calendar" => %{
                 "color_theme" => "some color_theme",
                 "id" => id,
                 "name" => "New Name",
                 "tenant_id" => tenant_id,
                 "visibility" => "public"
               },
               "status" => "ok"
             } = response

      assert is_binary(id)
      assert is_binary(tenant_id)
      assert calendar.tenant_id == tenant_id
    end

    test "delete calendar" do
      calendar = calendar_fixture()
      payload = %{"id" => calendar.id} |> authorize()

      response = sd_send("CALENDARS.DELETE|" <> Jason.encode!(payload))

      assert response["status"] == "ok"

      # Ensure it's gone
      get_resp = sd_send("CALENDARS.GET|" <> Jason.encode!(%{"id" => calendar.id}))
      assert get_resp["status"] == "error"
    end
  end
end
