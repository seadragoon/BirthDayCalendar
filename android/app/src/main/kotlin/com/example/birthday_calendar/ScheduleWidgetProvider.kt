package com.example.birthday_calendar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_schedule).apply {
                // ウィジェット全体をタップした時にアプリを起動
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_schedule_root, pendingIntent)

                // ヘッダーの日付ラベル
                val dateHeader = widgetData.getString("schedule_widget_date_header", null)
                if (!dateHeader.isNullOrEmpty()) {
                    setTextViewText(R.id.widget_schedule_header, "📅 $dateHeader")
                } else {
                    setTextViewText(R.id.widget_schedule_header, "📅 今日の予定")
                }

                // Flutter側から保存された予定 JSON 文字列を取得
                val rawJson = widgetData.getString("schedule_widget_data", null)

                if (rawJson.isNullOrEmpty()) {
                    setViewVisibility(R.id.widget_schedule_empty, View.VISIBLE)
                    setViewVisibility(R.id.widget_schedule_content, View.GONE)
                } else {
                    try {
                        val jsonArray = JSONArray(rawJson)
                        if (jsonArray.length() == 0) {
                            setViewVisibility(R.id.widget_schedule_empty, View.VISIBLE)
                            setViewVisibility(R.id.widget_schedule_content, View.GONE)
                        } else {
                            setViewVisibility(R.id.widget_schedule_empty, View.GONE)
                            setViewVisibility(R.id.widget_schedule_content, View.VISIBLE)

                            // 最大4件の設定
                            val containers = intArrayOf(
                                R.id.schedule_item1_container,
                                R.id.schedule_item2_container,
                                R.id.schedule_item3_container,
                                R.id.schedule_item4_container
                            )
                            val titleViews = intArrayOf(
                                R.id.schedule_item1_title,
                                R.id.schedule_item2_title,
                                R.id.schedule_item3_title,
                                R.id.schedule_item4_title
                            )
                            val timeViews = intArrayOf(
                                R.id.schedule_item1_time,
                                R.id.schedule_item2_time,
                                R.id.schedule_item3_time,
                                R.id.schedule_item4_time
                            )
                            val barViews = intArrayOf(
                                R.id.schedule_item1_bar,
                                R.id.schedule_item2_bar,
                                R.id.schedule_item3_bar,
                                R.id.schedule_item4_bar
                            )
                            val dividers = intArrayOf(
                                R.id.schedule_divider1,
                                R.id.schedule_divider2,
                                R.id.schedule_divider3
                            )

                            for (i in 0 until 4) {
                                if (i < jsonArray.length()) {
                                    val item = jsonArray.getJSONObject(i)
                                    val title = item.optString("title", "")
                                    val icon = item.optString("icon", "")
                                    val dateLabel = item.optString("date_label", "")
                                    val timeLabel = item.optString("time_label", "")
                                    val colorHex = item.optString("color_hex", "#7986CB")

                                    // タイトル（アイコン/スタンプ付き）
                                    val hasValidIcon = icon.isNotEmpty() && icon != "null"
                                    val displayTitle = if (hasValidIcon && !title.startsWith(icon)) {
                                        "$icon $title"
                                    } else {
                                        title
                                    }

                                    // 日時ラベル（例: "今日  10:00 - 11:30" / "明日  終日"）
                                    val displayTime = "$dateLabel  $timeLabel"

                                    setTextViewText(titleViews[i], displayTitle)
                                    setTextViewText(timeViews[i], displayTime)

                                    // カラーバー
                                    try {
                                        val parsedColor = Color.parseColor(colorHex)
                                        setInt(barViews[i], "setBackgroundColor", parsedColor)
                                    } catch (_: Exception) {
                                        // デフォルト色
                                    }

                                    setViewVisibility(containers[i], View.VISIBLE)

                                    if (i > 0 && i - 1 < dividers.size) {
                                        setViewVisibility(dividers[i - 1], View.VISIBLE)
                                    }
                                } else {
                                    setViewVisibility(containers[i], View.GONE)
                                    if (i > 0 && i - 1 < dividers.size) {
                                        setViewVisibility(dividers[i - 1], View.GONE)
                                    }
                                }
                            }
                        }
                    } catch (_: Exception) {
                        setViewVisibility(R.id.widget_schedule_empty, View.VISIBLE)
                        setViewVisibility(R.id.widget_schedule_content, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
