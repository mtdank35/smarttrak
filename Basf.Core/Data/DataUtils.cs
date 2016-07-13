using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data
{
    class DataUtils
    {
        public static bool IsDifferent(DateTime? oldValue, DateTime? newValue)
        {
            return (oldValue.HasValue && oldValue.Value != newValue) || (!oldValue.HasValue && newValue.HasValue);
        }
        public static bool IsDifferent(int? oldValue, int? newValue)
        {
            return (oldValue.HasValue && oldValue.Value != newValue) || (!oldValue.HasValue && newValue.HasValue);
        }
        public static bool IsDifferent(Int16? oldValue, Int16? newValue)
        {
            return (oldValue.HasValue && oldValue.Value != newValue) || (!oldValue.HasValue && newValue.HasValue);
        }
        public static bool IsDifferent(decimal? oldValue, decimal? newValue)
        {
            return (oldValue.HasValue && oldValue.Value != newValue) || (!oldValue.HasValue && newValue.HasValue);
        }
        public static bool IsDifferent(double? oldValue, double? newValue)
        {
            return (oldValue.HasValue && oldValue.Value != newValue) || (!oldValue.HasValue && newValue.HasValue);
        }
        public static bool IsDifferent(byte? oldValue, byte? newValue)
        {
            return (oldValue.HasValue && oldValue.Value != newValue) || (!oldValue.HasValue && newValue.HasValue);
        }
        public static bool IsDifferent(bool? oldValue, bool? newValue)
        {
            return (oldValue.HasValue && oldValue.Value != newValue) || (!oldValue.HasValue && newValue.HasValue);
        }

        public static bool IsDifferent(string oldValue, string newValue)
        {
            return (oldValue != null && oldValue != newValue) || (oldValue == null && newValue != null);
        }
        public static bool IsDifferent(DateTime oldValue, DateTime newValue)
        {
            return (oldValue != null && oldValue != newValue) || (oldValue == null && newValue != null);
        }
    }
}
