using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace BasfSvr.ServiceModel.Exceptions
{
    public class DoesNotExistException : Exception
    {
        public DoesNotExistException()
        { }

        protected DoesNotExistException(SerializationInfo info, StreamingContext context) : base(info, context)
        { }

        public DoesNotExistException(string message, Exception innerException) : base(message, innerException)
        { }

        public DoesNotExistException(string message) : base(message)
        { }
    }
}
