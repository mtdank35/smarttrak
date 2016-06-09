using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SlackChannelPost.Configuration
{
	public class SlackApiConf
	{
		public string Url { get; set; }
		public string Token { get; set; }
		public string Channel { get; set; }
		public string BotName { get; set; }
		public string IconEmoji { get; set; }

		public SlackApiConf()
		{
			Url = "http://localhost/api";
			Token = "token";
			Channel = "#support";
			BotName = "CtsOps SLACK";
			IconEmoji = ":heavy_exclamation_mark:";
        }
	}
}
