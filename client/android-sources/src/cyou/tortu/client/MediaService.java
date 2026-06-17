package cyou.tortu.client;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.media.MediaMetadata;
import android.media.session.MediaSession;
import android.media.session.PlaybackState;
import android.os.Build;
import android.os.IBinder;

public class MediaService extends Service {
    private static final String CHANNEL_ID = "TortuMediaPlayback";
    private static final int NOTIFICATION_ID = 101;

    private static MediaService sInstance = null;
    private MediaSession mSession = null;
    
    // Native callbacks to C++ code
    public static native void onPlayClicked();
    public static native void onPauseClicked();
    public static native void onNextClicked();
    public static native void onPrevClicked();

    public static void updateState(Context context, String title, String artist, boolean isPlaying, long duration, long position) {
        Intent intent = new Intent(context, MediaService.class);
        intent.putExtra("title", title);
        intent.putExtra("artist", artist);
        intent.putExtra("playing", isPlaying);
        intent.putExtra("duration", duration);
        intent.putExtra("position", position);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent);
        } else {
            context.startService(intent);
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        sInstance = this;
        createNotificationChannel();
        setupMediaSession();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String title = intent.getStringExtra("title");
            String artist = intent.getStringExtra("artist");
            boolean isPlaying = intent.getBooleanExtra("playing", false);
            long duration = intent.getLongExtra("duration", 0);
            long position = intent.getLongExtra("position", 0);
            
            updateSession(title, artist, isPlaying, duration, position);
        }
        return START_NOT_STICKY;
    }

    private void setupMediaSession() {
        mSession = new MediaSession(this, "TortuSession");
        mSession.setCallback(new MediaSession.Callback() {
            @Override
            public void onPlay() {
                onPlayClicked();
            }
            @Override
            public void onPause() {
                onPauseClicked();
            }
            @Override
            public void onSkipToNext() {
                onNextClicked();
            }
            @Override
            public void onSkipToPrevious() {
                onPrevClicked();
            }
        });
        mSession.setActive(true);
    }

    private void updateSession(String title, String artist, boolean isPlaying, long duration, long position) {
        if (mSession == null) return;

        // 1. Update Playback State
        int state = isPlaying ? PlaybackState.STATE_PLAYING : PlaybackState.STATE_PAUSED;
        long actions = PlaybackState.ACTION_PLAY | PlaybackState.ACTION_PAUSE | PlaybackState.ACTION_PLAY_PAUSE | PlaybackState.ACTION_SKIP_TO_NEXT | PlaybackState.ACTION_SKIP_TO_PREVIOUS;
        
        PlaybackState playbackState = new PlaybackState.Builder()
                .setState(state, position, 1.0f)
                .setActions(actions)
                .build();
        mSession.setPlaybackState(playbackState);

        // 2. Update Metadata
        MediaMetadata metadata = new MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, title != null ? title : "Tortu")
                .putString(MediaMetadata.METADATA_KEY_ARTIST, artist != null ? artist : "")
                .putLong(MediaMetadata.METADATA_KEY_DURATION, duration)
                .build();
        mSession.setMetadata(metadata);

        // 3. Update Notification
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        Notification.Builder builder = new Notification.Builder(this)
                .setContentTitle(title != null ? title : "Tortu")
                .setContentText(artist != null ? artist : "")
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentIntent(pendingIntent)
                .setStyle(new Notification.MediaStyle().setMediaSession(mSession.getSessionToken()))
                .setVisibility(Notification.VISIBILITY_PUBLIC);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(CHANNEL_ID);
        }

        Notification notification = builder.build();
        startForeground(NOTIFICATION_ID, notification);
    }

    @Override
    public void onDestroy() {
        if (mSession != null) {
            mSession.release();
        }
        sInstance = null;
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Tortu Media Service Channel",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(serviceChannel);
            }
        }
    }
}
