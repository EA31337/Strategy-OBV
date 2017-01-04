//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of OBV strategy based on the On Balance Volume indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iOBV
 * - https://www.mql5.com/en/docs/indicators/iOBV
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __OBV_Parameters__ = "-- Settings for the On Balance Volume indicator --"; // >>> OBV <<<
#ifdef __input__ input #endif ENUM_APPLIED_PRICE OBV_Applied_Price = 0; // Applied Price
#ifdef __input__ input #endif double OBV_SignalLevel = 0.00000000; // Signal level
#ifdef __input__ input #endif int OBV_SignalMethod = 0; // Signal method for M1 (0-

class OBV: public Strategy {
protected:

  double obv[H1][FINAL_ENUM_INDICATOR_INDEX];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

    public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the On Balance Volume indicator.
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      obv[index][i] = iOBV(symbol, tf, OBV_Applied_Price, i);
    }
    success = (bool) obv[index][CURR];
  }

  /**
   * Check if OBV indicator is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_OBV, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_OBV, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_OBV, tf, 0.0);
    switch (cmd) {
      case OP_BUY:
        break;
      case OP_SELL:
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    return result;
  }
};
