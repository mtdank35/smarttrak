using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SlackChannelPost.Configuration
{
	public class DbConf
	{
		public string Dbcs { get; set; }

		public DbConf()
		{
			Dbcs = "server=localhost;database=CrashRep;Uid=sa;pwd=123";
		}
	}
}
