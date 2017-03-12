defmodule AITest do
  use ExUnit.Case

  setup do
    {:ok, ai} = AI.start_link()
    {:ok, task_sup} = Task.Supervisor.start_link(name: AI.TaskSupervisor) 

    on_exit fn ->
      assert_down task_sup
      assert_down ai
    end
  end

  test "AI should create a new sesssion for a sender that doesn't has one" do
    sender = "12345"
    {_, %{context: %{}, fbid: ^sender, tasks: []}} = AI.create_session sender
  end

  test "AI should not create a session when a sender has an existing valid one" do
    state = %{"some-session-id" => %{fbid: 123, context: %{}, tasks: []}}
    {:reply, result, new_state} = AI.handle_call({:create_session, 123}, AI, state)

    assert result == {"some-session-id", %{fbid: 123, context: %{}, tasks: []}}
    assert new_state == state
  end 

  test "A session should be removed when it's context contains 'done'"  do
    task1_ref = make_ref()
    task2_ref = make_ref()
    current_state = %{
      "some-session-id" => %{
        fbid: 123,
        context: %{},
        tasks: [task1_ref]
      },
      "some-other-session-id" => %{
        fbid: 234,
        context: %{},
        tasks: [task2_ref]
      }
    }
    {:noreply, new_state} = AI.handle_info({task1_ref, {:ok, %{done: true}}}, current_state)
    assert new_state == %{"some-other-session-id" => %{fbid: 234, context: %{}, tasks: [task2_ref]}}
  end 

  test "Session context should be updated when it's context not contains done key" do
    task1_ref = make_ref()
    task2_ref = make_ref()

    current_state = %{
      "some-session-id" => %{
        fbid: 123,
        context: %{},
        tasks: [task1_ref]
      },
      "some-other-session-id" => %{
        fbid: 234,
        context: %{},
        tasks: [task2_ref]
      }
    }
    {:noreply, new_state} = AI.handle_info({task1_ref, {:ok, %{some_key: 1}}}, current_state)
    assert new_state ==  %{
      "some-session-id" => %{
        fbid: 123,
        context: %{some_key: 1},
        tasks: [] 
      },
      "some-other-session-id" => %{
        fbid: 234,
        context: %{},
        tasks: [task2_ref]
      }
    }
  end

  test "A task ref should be added to a session's list of tasks" do
    session_id = "some-session-id"
    current_state = %{session_id => %{context: %{}, fbid: 123, tasks: []}}
    
    {:noreply, new_state} = AI.handle_cast({:process, "foo bar", session_id, %{}}, current_state)
    %{^session_id => %{context: %{}, tasks: [h | _], fbid: 123}} = new_state
    assert is_reference(h)
  end

  test "AI should receive {:ok, context} when a wit task is done" do
    ai = Process.whereis AI
    :erlang.trace(ai, true, [:receive])
    AI.process("Foo bar", 123)
    
    assert_receive {:trace, ^ai, :receive, {_, {:ok, %{random_key: :random_value}}}}
  end

  test "Retrieving an existing session" do
    current_state = %{
      "session-id" => %{}
    }
    {:reply, %{}, ^current_state} = AI.handle_call({:get_session, "session-id"}, AI, current_state)
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid) 
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end