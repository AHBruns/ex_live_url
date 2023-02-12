defmodule ExLiveUrlTest do
  use ExUnit.Case
  doctest ExLiveUrl

  # unit tests

  test "handle_info_hook ignores other messages" do
    socket = make_socket()
    assert ExLiveUrl.handle_info_hook("who cares", socket) == {:cont, socket}
  end

  test "get_path/1 returns the path" do
    assert make_socket() |> ExLiveUrl.get_path() == make_socket().assigns[ExLiveUrl].path
  end

  test "get_params/1 returns the params" do
    assert make_socket() |> ExLiveUrl.get_params() == make_socket().assigns[ExLiveUrl].params
  end

  test "get_url/1 returns the correct URL" do
    assert make_socket() |> ExLiveUrl.get_url() == "/base?x=y"
  end

  test "get_url/1 returns the correct URL at /" do
    assert ExLiveUrl.get_url(%Phoenix.LiveView.Socket{
             assigns: %{ExLiveUrl => %{path: "/", params: %{}}}
           }) == "/?"
  end

  test "get_url/1 returns the correct URL when params are nested" do
    assert ExLiveUrl.get_url(%Phoenix.LiveView.Socket{
             assigns: %{
               ExLiveUrl => %{
                 path: "/base",
                 params: %{"x" => [%{"y" => "z"}, "a"]}
               }
             }
           }) == "/base?x[][y]=z&x[]=a"
  end

  test "push_patch/2 applies a push patch correctly" do
    assert {:live, :patch, %{kind: :push, to: "/base/test?test=passed&x=y"}} ==
             ExLiveUrl.push_patch(make_socket(), fn url ->
               %{path: url.path <> "/test", params: Map.put(url.params, "test", "passed")}
             end).redirected
  end

  test "push_patch/2 applies a replace patch correctly" do
    assert {:live, :patch, %{kind: :replace, to: "/base/test?test=passed&x=y"}} ==
             ExLiveUrl.push_patch(make_socket(), fn url ->
               %{
                 path: url.path <> "/test",
                 params: Map.put(url.params, "test", "passed"),
                 replace: true
               }
             end).redirected
  end

  test "push_navigation/2 applies a push patch correctly" do
    assert {:live, :redirect, %{kind: :push, to: "/base/test?test=passed&x=y"}} ==
             ExLiveUrl.push_navigate(make_socket(), fn url ->
               %{path: url.path <> "/test", params: Map.put(url.params, "test", "passed")}
             end).redirected
  end

  test "push_navigation/2 applies a replace patch correctly" do
    assert {:live, :redirect, %{kind: :replace, to: "/base/test?test=passed&x=y"}} ==
             ExLiveUrl.push_navigate(make_socket(), fn url ->
               %{
                 path: url.path <> "/test",
                 params: Map.put(url.params, "test", "passed"),
                 replace: true
               }
             end).redirected
  end

  test "redirect/2 redirects internally correctly" do
    assert {:redirect, %{to: "/base/test?test=passed&x=y"}} ==
             ExLiveUrl.redirect(make_socket(), fn url ->
               %{path: url.path <> "/test", params: Map.put(url.params, "test", "passed")}
             end).redirected
  end

  test "redirect/2 redirects externally correctly" do
    assert {:redirect, %{external: "https://google.com"}} ==
             ExLiveUrl.redirect(make_socket(), fn _url -> "https://google.com" end).redirected
  end

  test "send_push_patch/1 sends correct command" do
    transform_fun = fn _ -> nil end

    assert :ok == ExLiveUrl.send_push_patch(transform_fun)
    assert_received({ExLiveUrl, :do_push_patch, ^transform_fun})
  end

  test "send_push_patch/2 sends correct command" do
    transform_fun = fn _ -> nil end

    assert :ok == ExLiveUrl.send_push_patch(self(), transform_fun)

    assert_received({ExLiveUrl, :do_push_patch, ^transform_fun})
  end

  test "send_push_navigate/1 sends correct command" do
    transform_fun = fn _ -> nil end

    assert :ok == ExLiveUrl.send_push_navigate(transform_fun)
    assert_received({ExLiveUrl, :do_push_navigate, ^transform_fun})
  end

  test "send_push_navigate/2 sends correct message" do
    transform_fun = fn _ -> nil end

    assert :ok == ExLiveUrl.send_push_navigate(self(), transform_fun)
    assert_received({ExLiveUrl, :do_push_navigate, ^transform_fun})
  end

  test "send_redirect/1 sends correct message" do
    transform_fun = fn _ -> nil end

    assert :ok == ExLiveUrl.send_redirect(transform_fun)
    assert_received({ExLiveUrl, :do_redirect, ^transform_fun})
  end

  test "send_redirect/2 sends correct message" do
    transform_fun = fn _ -> nil end

    assert :ok == ExLiveUrl.send_redirect(self(), transform_fun)
    assert_received({ExLiveUrl, :do_redirect, ^transform_fun})
  end

  # integration tests

  test "send_push_patch halts handle_info and causes a redirect" do
    ExLiveUrl.send_push_patch(fn url ->
      %{
        path: url.path <> "/test",
        params: Map.put(url.params, "test", "passed"),
        replace: true
      }
    end)

    {action, socket} =
      receive do
        message -> message
      end
      |> ExLiveUrl.handle_info_hook(make_socket())

    assert action == :halt

    assert {:live, :patch, %{kind: :replace, to: "/base/test?test=passed&x=y"}} ==
             socket.redirected
  end

  test "send_push_navigate halts handle_info and causes a redirect" do
    ExLiveUrl.send_push_navigate(fn url ->
      %{
        path: url.path <> "/test",
        params: Map.put(url.params, "test", "passed"),
        replace: true
      }
    end)

    {action, socket} =
      receive do
        message -> message
      end
      |> ExLiveUrl.handle_info_hook(make_socket())

    assert action == :halt

    assert {:live, :redirect, %{kind: :replace, to: "/base/test?test=passed&x=y"}} ==
             socket.redirected
  end

  test "send_redirect halts handle_info and causes a redirect" do
    ExLiveUrl.send_redirect(fn _url -> "https://google.com" end)

    {action, socket} =
      receive do
        message -> message
      end
      |> ExLiveUrl.handle_info_hook(make_socket())

    assert action == :halt
    assert {:redirect, %{external: "https://google.com"}} == socket.redirected
  end

  test "data gets store in handle_params correctly" do
    {action, socket} =
      ExLiveUrl.handle_params_hook(
        %{"a" => ["b", %{"c" => "d"}]},
        "https://test.com/test",
        make_socket()
      )

    assert action == :cont
    assert ExLiveUrl.get_path(socket) == "/test"
    assert ExLiveUrl.get_params(socket) == %{"a" => ["b", %{"c" => "d"}]}
    assert ExLiveUrl.get_url(socket) == "/test?a[]=b&a[][c]=d"
  end

  # helpers

  defp make_socket do
    %Phoenix.LiveView.Socket{
      assigns: %{
        :__changed__ => %{},
        ExLiveUrl => %{
          path: "/base",
          params: %{"x" => "y"}
        }
      }
    }
  end
end
