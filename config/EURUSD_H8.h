/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_OBV_Params_H8 : OBVParams {
  Indi_OBV_Params_H8() : OBVParams(indi_obv_defaults, PERIOD_H8) { shift = 0; }
} indi_obv_h8;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_OBV_Params_H8 : StgParams {
  // Struct constructor.
  Stg_OBV_Params_H8() : StgParams(stg_obv_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_obv_h8;
