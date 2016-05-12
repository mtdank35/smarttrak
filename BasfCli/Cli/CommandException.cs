using System;

namespace BasfCli
{
	public class CommandException : Exception
	{
		public CommandException()
		{
		}

		public CommandException(string message)
			: base(message)
		{
		}
	}
}
