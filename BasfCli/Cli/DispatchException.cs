using System;

namespace BasfCli
{
	public class DispatchException : Exception
	{
		public DispatchException()
		{
		}

		public DispatchException(string message)
			: base(message)
		{
		}
	}
}
