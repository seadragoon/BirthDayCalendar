package com.example.birthday_calendar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Shader
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.io.File

class PhotoCountdownWidget2x2Provider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_photo_countdown_2x2).apply {
                // ウィジェット全体タップでアプリ起動
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                val rawJson = widgetData.getString("photo_countdown_widget_data", null)

                if (rawJson.isNullOrEmpty()) {
                    setViewVisibility(R.id.widget_empty_view, View.VISIBLE)
                    setViewVisibility(R.id.widget_content, View.GONE)
                } else {
                    try {
                        val json = JSONObject(rawJson)
                        val hasData = json.optBoolean("has_data", false)

                        if (!hasData) {
                            setViewVisibility(R.id.widget_empty_view, View.VISIBLE)
                            setViewVisibility(R.id.widget_content, View.GONE)
                        } else {
                            setViewVisibility(R.id.widget_empty_view, View.GONE)
                            setViewVisibility(R.id.widget_content, View.VISIBLE)

                            setTextViewText(R.id.item_name, json.optString("name", ""))
                            setTextViewText(R.id.item_date, json.optString("date_label", ""))

                            val daysLabel = json.optString("days_label", "")
                            setTextViewText(R.id.item_days, daysLabel)

                            val isToday = json.optBoolean("is_today", false)
                            if (isToday) {
                                setInt(R.id.item_days, "setBackgroundResource", R.drawable.widget_chip_celebrate)
                            } else {
                                setInt(R.id.item_days, "setBackgroundResource", R.drawable.widget_chip_primary)
                            }

                            // 写真の読み込みと円形クロップ描画
                            val photoPath = json.optString("photo_path", "")
                            var photoLoaded = false
                            if (photoPath.isNotEmpty()) {
                                val file = File(photoPath)
                                if (file.exists()) {
                                    try {
                                        // ウィジェット向けにリサイズしてデコード
                                        val options = BitmapFactory.Options().apply {
                                            inSampleSize = 2
                                        }
                                        val bitmap = BitmapFactory.decodeFile(photoPath, options)
                                        if (bitmap != null) {
                                            val circularBitmap = toCircularBitmap(bitmap)
                                            setImageViewBitmap(R.id.widget_photo, circularBitmap)
                                            photoLoaded = true
                                        }
                                    } catch (_: Exception) {}
                                }
                            }

                            if (!photoLoaded) {
                                // 写真がない場合はプレースホルダー
                                setImageViewResource(R.id.widget_photo, R.drawable.widget_photo_placeholder)
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

    private fun toCircularBitmap(bitmap: Bitmap): Bitmap {
        val size = Math.min(bitmap.width, bitmap.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)

        val x = (bitmap.width - size) / 2
        val y = (bitmap.height - size) / 2
        val cropped = Bitmap.createBitmap(bitmap, x, y, size, size)

        val paint = Paint().apply {
            isAntiAlias = true
            shader = BitmapShader(cropped, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        }

        val radius = size / 2f
        canvas.drawCircle(radius, radius, radius, paint)
        return output
    }
}
