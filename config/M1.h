/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_OBV_Params_M1 : OBVParams {
  Indi_OBV_Params_M1() : OBVParams(indi_obv_defaults, PERIOD_M1) {
    applied_price = (ENUM_APPLIED_PRICE)0;
    shift = 0;
  }
} indi_obv_m1;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_OBV_Params_M1 : StgParams {
  // Struct constructor.
  Stg_OBV_Params_M1() : StgParams(stg_obv_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_filter = 32;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_obv_m1;
