using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SlackChannelPost
{
	public class SlackChatMessage
	{
		//token xxxx-xxxxxxxxx-xxxx Required
		//Authentication token(Requires scope: post)
		//channel C1234567890 Required
		//Channel, private group, or IM channel to send message to.Can be an encoded ID, or a name.See below for more details.
		//text    Hello world Required
		//Text of the message to send.See below for an explanation of formatting.
		//username My Bot Optional
		//Name of bot.
		//as_user true	Optional
		//Pass true to post the message as the authed user, instead of as a bot
		//parse full    Optional
		//Change how messages are treated. See below.
		//link_names  1	Optional
		//Find and link channel names and usernames.
		//attachments[{ "pretext": "pre-hello", "text": "text-world"}]	Optional
		//Structured message attachments.
		//unfurl_links    true	Optional
		//Pass true to enable unfurling of primarily text-based content.
		//unfurl_media    false	Optional
		//Pass false to disable unfurling of media content.
		//icon_url http://lorempixel.com/48/48	Optional	
		//URL to an image to use as the icon for this message
		//icon_emoji	:chart_with_upwards_trend:	Optional
		//emoji to use as the icon for this message.Overrides icon_url.
		public string token { get; set; }
		public string channel { get; set; }
		public string text { get; set; }
		public string username { get { return "CtsOps SLACK BOT"; } }
		public StructuredMsgAttachment[] attachments { get; set; }
		public string icon_emoji { get; set; }
	}

	public class StructuredMsgAttachment
	{
		public string fallback { get; set; }
		public string pretext { get; set; }
		public string title { get; set; }
		public string title_link { get; set; }
		public string text { get; set; }
		public string color { get; set; }
	}

	public class SlackResponseContent
	{
		public bool ok { get; set; }
		public string error { get; set; }
	}
}
