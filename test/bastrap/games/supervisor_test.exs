defmodule Bastrap.Games.SupervisorTest do
  use Bastrap.DataCase, async: true

  alias Bastrap.Games.Supervisor
  alias Bastrap.AccountsFixtures

  setup do
    users = Enum.map(1..2, fn _ -> AccountsFixtures.user_fixture() end)
    %{users: users}
  end

  describe "start_game/1" do
    test "starts a new game server", %{users: [user | _]} do
      assert {:ok, pid} = Supervisor.create_game(user)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "starts multiple game servers", %{users: [user1, user2]} do
      assert {:ok, pid1} = Supervisor.create_game(user1)
      assert {:ok, pid2} = Supervisor.create_game(user2)

      assert is_pid(pid1)
      assert is_pid(pid2)
      assert pid1 != pid2
      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
    end
  end

  describe "supervisor" do
    test "is started with the application" do
      supervisor_pid = Process.whereis(Bastrap.Games.Supervisor)
      assert is_pid(supervisor_pid)
      assert Process.alive?(supervisor_pid)
    end
  end
end
