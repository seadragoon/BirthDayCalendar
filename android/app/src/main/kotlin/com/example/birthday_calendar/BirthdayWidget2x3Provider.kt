package com.example.birthday_calendar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class BirthdayWidget2x3Provider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_birthday_2x3).apply {
                // ウィジェット全体をタップした時にアプリを起動
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                // Flutter側から保存された JSON 文字列を取得
                val rawJson = widgetData.getString("birthday_widget_data", null)

                if (rawJson.isNullOrEmpty()) {
                    setViewVisibility(R.id.widget_empty_view, View.VISIBLE)
                    setViewVisibility(R.id.widget_content, View.GONE)
                } else {
                    try {
                        val jsonArray = JSONArray(rawJson)
                        if (jsonArray.length() == 0) {
                            setViewVisibility(R.id.widget_empty_view, View.VISIBLE)
                            setViewVisibility(R.id.widget_content, View.GONE)
                        } else {
                            setViewVisibility(R.id.widget_empty_view, View.GONE)
                            setViewVisibility(R.id.widget_content, View.VISIBLE)

                            // 1人目
                            val item1 = jsonArray.getJSONObject(0)
                            setTextViewText(R.id.item1_name, item1.optString("name", ""))
                            setTextViewText(R.id.item1_date, item1.optString("date_label", ""))
                            setTextViewText(R.id.item1_days, item1.optString("days_label", ""))
                            setViewVisibility(R.id.item1_container, View.VISIBLE)

                            // 2人目
                            if (jsonArray.length() > 1) {
                                val item2 = jsonArray.getJSONObject(1)
                                setTextViewText(R.id.item2_name, item2.optString("name", ""))
                                setTextViewText(R.id.item2_date, item2.optString("date_label_short", ""))
                                setTextViewText(R.id.item2_days, item2.optString("days_label", ""))
                                setViewVisibility(R.id.item2_container, View.VISIBLE)
                                setViewVisibility(R.id.divider1, View.VISIBLE)
                            } else {
                                setViewVisibility(R.id.item2_container, View.GONE)
                                setViewVisibility(R.id.divider1, View.GONE)
                            }

                            // 3人目
                            if (jsonArray.length() > 2) {
                                val item3 = jsonArray.getJSONObject(2)
                                setTextViewText(R.id.item3_name, item3.optString("name", ""))
                                setTextViewText(R.id.item3_date, item3.optString("date_label_short", ""))
                                setTextViewText(R.id.item3_days, item3.optString("days_label", ""))
                                setViewVisibility(R.id.item3_container, View.VISIBLE)
                                setViewVisibility(R.id.divider2, View.VISIBLE)
                            } else {
                                setViewVisibility(R.id.item3_container, View.GONE)
                                setViewVisibility(R.id.divider2, View.GONE)
                            }
                        }
                    } catch (_: Exception) {
                        setViewVisibility(R.id.widget_empty_view, View.VISIBLE)
                        setViewVisibility(R.id.widget_content, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
