defmodule LiveQchatexWeb.LiveChat.Handlers do
  alias __MODULE__
  alias LiveQchatex.Chats
  alias LiveQchatex.Models
  alias Phoenix.LiveView.Socket

  @callback handle_chat_created(Socket.t(), %Models.Chat{}) :: Socket.t()
  @callback handle_chat_updated(Socket.t(), %Models.Chat{}) :: Socket.t()
  @callback handle_chat_cleared(Socket.t(), Integer.t()) :: Socket.t()

  @callback handle_user_created(Socket.t(), %Models.User{}) :: Socket.t()
  @callback handle_user_updated(Socket.t(), %Models.User{}) :: Socket.t()
  @callback handle_user_cleared(Socket.t(), Integer.t()) :: Socket.t()

  @callback handle_presence_payload(Socket.t(), String.t(), Map.t()) :: Socket.t()

  defmacro __using__(_opts \\ []) do
    quote do
      require Logger

      @behaviour Handlers

      def handle_info({[:chat, :created], chat} = info, socket) do
        Logger.debug("HANDLE CHAT CREATED: #{inspect(info)}", ansi_color: :magenta)

        {:noreply, socket |> handle_chat_created(chat)}
      end

      def handle_info({[:chat, :updated], chat} = info, socket) do
        Logger.debug("HANDLE CHAT UPDATED: #{inspect(info)}", ansi_color: :magenta)

        {:noreply, socket |> handle_chat_updated(chat)}
      end

      def handle_info({[:chat, :cleared], counter} = info, socket) do
        Logger.debug("HANDLE CHAT CLEARED: #{inspect(info)}", ansi_color: :magenta)

        {:noreply, socket |> handle_chat_cleared(counter)}
      end

      def handle_info({[:user, :created], user} = info, socket) do
        Logger.debug("HANDLE USER CREATED: #{inspect(info)}", ansi_color: :magenta)

        {:noreply, socket |> handle_user_created(user)}
      end

      def handle_info({[:user, :updated], user} = info, socket) do
        Logger.debug("HANDLE USER UPDATED: #{inspect(info)}", ansi_color: :magenta)

        {:noreply, socket |> handle_user_updated(user)}
      end

      def handle_info({[:user, :cleared], counter} = info, socket) do
        Logger.debug("HANDLE USER CLEARED: #{inspect(info)}", ansi_color: :magenta)

        {:noreply, socket |> handle_user_cleared(counter)}
      end

      def handle_info(%{event: "presence_diff", topic: topic, payload: payload}, socket) do
        Logger.debug("HANDLE PRESENCE FOR '#{topic}': #{inspect(payload)}", ansi_color: :magenta)

        {:noreply, socket |> handle_presence_payload(topic, payload)}
      end

      def handle_info({:hearthbeat, _, _} = info, socket) do
        Logger.debug("HANDLE HEARTHBEAT: #{inspect(info)}", ansi_color: :magenta)

        Chats.handle_hearthbeat(info, socket)
      end

      def handle_chat_created(socket, _chat), do: socket
      defoverridable handle_chat_created: 2

      def handle_chat_updated(socket, _chat), do: socket
      defoverridable handle_chat_updated: 2

      def handle_chat_cleared(socket, _counter), do: socket
      defoverridable handle_chat_cleared: 2

      def handle_user_created(socket, _chat), do: socket
      defoverridable handle_user_created: 2

      def handle_user_updated(socket, _user), do: socket
      defoverridable handle_user_updated: 2

      def handle_user_cleared(socket, _counter), do: socket
      defoverridable handle_user_cleared: 2

      def handle_presence_payload(socket, _topic, _payload), do: socket
      defoverridable handle_presence_payload: 3
    end
  end
end
