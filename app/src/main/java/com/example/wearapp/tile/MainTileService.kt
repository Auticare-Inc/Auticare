//package com.example.wearapp.tile
//
//import android.content.Context
//import androidx.compose.runtime.Composable
//import androidx.compose.ui.platform.LocalContext
//import androidx.compose.ui.tooling.preview.Devices
//import androidx.compose.ui.tooling.preview.Preview
//import androidx.wear.tiles.LayoutElementBuilders
//import androidx.wear.tiles.RequestBuilders
//import androidx.wear.tiles.ResourceBuilders
//import androidx.wear.tiles.TileBuilders
//import androidx.wear.tiles.TimelineBuilders
//import androidx.wear.tiles.material.Text
//import androidx.wear.tiles.material.Typography
//import androidx.wear.tiles.material.layouts.PrimaryLayout
//import com.google.android.horologist.compose.tools.LayoutRootPreview
//import com.google.android.horologist.compose.tools.buildDeviceParameters
//import com.google.android.horologist.tiles.CoroutinesTileService
//
//private const val RESOURCES_VERSION = "0"
//
///**
// * Skeleton for a tile with no images.
// */
//class MainTileService : CoroutinesTileService() {
//
//    override suspend fun resourcesRequest(
//        requestParams: RequestBuilders.ResourcesRequest
//    ): ResourceBuilders.Resources {
//        return ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build()
//    }
//
//    override suspend fun tileRequest(
//        requestParams: RequestBuilders.TileRequest
//    ): TileBuilders.Tile {
//        val singleTileTimeline = TimelineBuilders.Timeline.Builder().addTimelineEntry(
//            TimelineBuilders.TimelineEntry.Builder().setLayout(
//                LayoutElementBuilders.Layout.Builder().setRoot(tileLayout(this)).build()
//            ).build()
//        ).build()
//
//        return TileBuilders.Tile.Builder().setResourcesVersion(RESOURCES_VERSION)
//            .setTimeline(singleTileTimeline).build()
//    }
//}
//
//private fun tileLayout(context: Context): LayoutElementBuilders.LayoutElement {
//    return PrimaryLayout.Builder(buildDeviceParameters(context.resources))
//        .setContent(
//            Text.Builder(context, "Hello World!")
//                .setTypography(Typography.TYPOGRAPHY_CAPTION1)
//                .build()
//        ).build()
//}
//
//@Preview(
//    device = Devices.WEAR_OS_SMALL_ROUND,
//    showSystemUi = true,
//    backgroundColor = 0xff000000,
//    showBackground = true
//)
//@Composable
//fun TilePreview() {
//    LayoutRootPreview(root = tileLayout(LocalContext.current))
//}
package com.example.wearapp.tile

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleRegistry
import androidx.wear.tiles.LayoutElementBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.ResourceBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TimelineBuilders
import androidx.wear.tiles.material.Text
import androidx.wear.tiles.material.Typography
import androidx.wear.tiles.material.layouts.PrimaryLayout
import com.google.android.horologist.compose.tools.LayoutRootPreview
import com.google.android.horologist.compose.tools.buildDeviceParameters
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

private const val RESOURCES_VERSION = "0"

/**
 * Skeleton for a tile with no images.
 */
abstract class MainTileService : TileService() {

    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.Main + serviceJob)

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        val singleTileTimeline = TimelineBuilders.Timeline.Builder().addTimelineEntry(
            TimelineBuilders.TimelineEntry.Builder().setLayout(
                LayoutElementBuilders.Layout.Builder().setRoot(tileLayout(this)).build()
            ).build()
        ).build()

        val tile = TileBuilders.Tile.Builder().setResourcesVersion(RESOURCES_VERSION)
            .setTimeline(singleTileTimeline).build()

        return Futures.immediateFuture(tile)
    }

    fun onTileResourcesRequest(requestParams: RequestBuilders.ResourcesRequest): ListenableFuture<ResourceBuilders.Resources> {
        val resources = ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build()
        return Futures.immediateFuture(resources)
    }
}

private fun tileLayout(context: Context): LayoutElementBuilders.LayoutElement {
    return PrimaryLayout.Builder(buildDeviceParameters(context.resources))
        .setContent(
            Text.Builder(context, "Hello World!")
                .setTypography(Typography.TYPOGRAPHY_CAPTION1)
                .build()
        ).build()
}

@Preview(
    device = Devices.WEAR_OS_SMALL_ROUND,
    showSystemUi = true,
    backgroundColor = 0xff000000,
    showBackground = true
)
@Composable
fun TilePreview() {
    LayoutRootPreview(root = tileLayout(LocalContext.current))
}