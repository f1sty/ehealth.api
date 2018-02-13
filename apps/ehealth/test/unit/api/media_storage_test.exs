defmodule EHealth.Unit.API.MediaStorageTest do
  @moduledoc false

  import ExUnit.CaptureLog

  use EHealth.Web.ConnCase

  alias EHealth.API.MediaStorage

  describe "create_signed_url/2" do
    setup do
      original_level = Logger.level()
      Logger.configure(level: :info)

      on_exit(fn ->
        Logger.configure(level: original_level)
      end)

      :ok
    end

    test "writes to log" do
      fun = fn ->
        MediaStorage.create_signed_url("PUT", "some_bucket", "my_resource", "my_id", some_header: "x")
      end

      log = capture_log([level: :info], fun)

      assert log =~ ~s("log_type":"microservice_request")
      assert log =~ ~s("headers":{"some_header":"x"})

      assert log =~
               ~s("body":{"secret":{"action":"PUT","bucket":"some_bucket","content_type":"application/octet-stream",) <>
                 ~s("resource_id":"my_id","resource_name":"my_resource"}})

      assert log =~ ~s("action":"POST")
    end
  end
end
