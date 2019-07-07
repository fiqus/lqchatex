defmodule LiveQchatexWeb.ChatView do
  use LiveQchatexWeb, :view

  def parse_title(assigns, chat, user) do
    {class, click, title} =
      if chat.user_id == user.id,
        do: {"chat-owner", "show_input_title", "Click to change the title!"},
        else: {"", "", ""}

    if Map.get(assigns, :click) == "show_input_title" do
      ~s(<form action="#send" phx-submit="update_title">
        <span><input type="text" name="title" value="#{chat.title}" maxlength="100"/></span>
      </form>)
    else
      ~s(<p class="#{class}" phx-click="click" phx-value="#{click}" title="#{title}">#{chat.title}</p>)
    end
  end

  def parse_member(assigns, chat, user, member) do
    {class, click, title} =
      if member.id == user.id,
        do: {"myself", "show_input_nickname", "Click to change your nick!"},
        else: {"member", "", "SOON: Click to send private message!"}

    if member.id == user.id && Map.get(assigns, :click) == "show_input_nickname" do
      ~s(<form action="#send" phx-submit="update_nickname">
        <p><input type="text" name="nick" class="focus-select" value="#{member.nickname}" maxlength="20"/></p>
      </form>)
    else
      ~s(<p class="#{class}" phx-click="click" phx-value="#{click}" title="#{title}" style="color:#{
        member_color(member.id)
      }">#{parse_member_nickname(chat, member)}</p>)
    end
  end

  def ellipsis(true), do: "<span class=\"ellipsis\"></span>"
  def ellipsis(false), do: nil

  # @TODO Improve colours!
  def member_color(id) do
    "##{id |> Base.encode16() |> binary_part(0, 6)}"
  end

  def parse_timestamp(ts) when is_integer(ts) do
    {:ok, %DateTime{hour: hour, minute: minute, second: second}} = DateTime.from_unix(ts)
    format_date_values([hour, minute, second], ":")
  end

  def parse_timestamp(_), do: "-"

  defp format_date_values(values, glue),
    do:
      values
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.pad_leading(&1, 2, "0"))
      |> Enum.join(glue)

  defp parse_member_nickname(chat, member) do
    nick = "#{member.nickname}#{ellipsis(member.typing)}"

    if chat.user_id == member.id,
      do: "<span title=\"Chat owner\">*</span> " <> nick,
      else: nick
  end
end
