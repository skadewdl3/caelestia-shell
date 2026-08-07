#include <bit>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>

namespace {

using gboolean = int;
using guint = unsigned int;
using gulong = unsigned long;

struct GError;
struct GKeyFile;
struct GtkBuilder;

using BuilderAddFromResource = guint (*)(GtkBuilder*, const char*, GError**);
using BuilderConnectSignals = void (*)(GtkBuilder*, void*);
using BuilderGetObject = void* (*)(GtkBuilder*, const char*);
using ButtonSetAlwaysShowImage = void (*)(void*, gboolean);
using ButtonSetImagePosition = void (*)(void*, int);
using ButtonSetLabel = void (*)(void*, const char*);
using ButtonGetImage = void* (*)(void*);
using ImageSetFromIconName = void (*)(void*, const char*, int);
using KeyFileGetBoolean = gboolean (*)(GKeyFile*, const char*, const char*, GError**);
using SignalConnectData = gulong (*)(void*, const char*, void (*)(), void*, void (*)(void*, void*), int);
using SignalHandlersDisconnectMatched = guint (*)(void*, int, guint, unsigned int, void*, void*, void*);
using WidgetDestroy = void (*)(void*);
using WidgetSetTooltipText = void (*)(void*, const char*);

template <typename T> T loadNext(const char* name) {
    return std::bit_cast<T>(dlsym(RTLD_NEXT, name));
}

void* editorWindow;
WidgetDestroy destroyWidget;
GtkBuilder* swappyBuilder;
bool actionsWired;

void discardTemporaryCapture() {
    if (const char* path = std::getenv("CAELESTIA_SCREENSHOT_PATH"))
        std::remove(path);
}

void closeEditor(void*, void*) {
    discardTemporaryCapture();
    if (editorWindow && destroyWidget)
        destroyWidget(editorWindow);
}

void makeLabelledButton(GtkBuilder* builder, const char* id, const char* label) {
    const auto getObject = loadNext<BuilderGetObject>("gtk_builder_get_object");
    const auto setLabel = loadNext<ButtonSetLabel>("gtk_button_set_label");
    const auto alwaysShowImage = loadNext<ButtonSetAlwaysShowImage>("gtk_button_set_always_show_image");
    const auto setImagePosition = loadNext<ButtonSetImagePosition>("gtk_button_set_image_position");
    if (!getObject || !setLabel || !alwaysShowImage || !setImagePosition)
        return;

    void* button = getObject(builder, id);
    if (!button)
        return;

    setLabel(button, label);
    alwaysShowImage(button, 1);
    setImagePosition(button, 0); // GTK_POS_LEFT
}

void customiseUi(GtkBuilder* builder) {
    const auto getObject = loadNext<BuilderGetObject>("gtk_builder_get_object");
    if (!getObject)
        return;

    swappyBuilder = builder;
    editorWindow = getObject(builder, "paint-window");
    makeLabelledButton(builder, "copy", "Copy");
    makeLabelledButton(builder, "save", "Save");

    void* editButton = getObject(builder, "btn-toggle-panel");
    const auto getImage = loadNext<ButtonGetImage>("gtk_button_get_image");
    const auto setIcon = loadNext<ImageSetFromIconName>("gtk_image_set_from_icon_name");
    const auto setTooltip = loadNext<WidgetSetTooltipText>("gtk_widget_set_tooltip_text");
    if (editButton && getImage && setIcon) {
        if (void* image = getImage(editButton))
            setIcon(image, "document-edit-symbolic", 4); // GTK_ICON_SIZE_BUTTON
        if (setTooltip)
            setTooltip(editButton, "Toggle editing tools");
    }

    if (void* deleteButton = getObject(builder, "clear"); deleteButton && setTooltip)
        setTooltip(deleteButton, "Delete screenshot");
}

void wireActions(GtkBuilder* builder) {
    if (actionsWired)
        return;

    const auto getObject = loadNext<BuilderGetObject>("gtk_builder_get_object");
    const auto connectSignal = loadNext<SignalConnectData>("g_signal_connect_data");
    const auto disconnectMatched = loadNext<SignalHandlersDisconnectMatched>("g_signal_handlers_disconnect_matched");
    destroyWidget = loadNext<WidgetDestroy>("gtk_widget_destroy");
    if (!getObject || !connectSignal || !destroyWidget)
        return;

    void* deleteButton = getObject(builder, "clear");
    if (deleteButton && disconnectMatched) {
        // Swappy's trash button normally only clears annotations. Remove that
        // handler so the control unambiguously discards the whole capture.
        if (void* clearHandler = dlsym(RTLD_DEFAULT, "clear_clicked_handler"))
            disconnectMatched(deleteButton, 1 << 3, 0, 0, nullptr, clearHandler, nullptr); // G_SIGNAL_MATCH_FUNC
    }

    const auto callback = reinterpret_cast<void (*)()>(closeEditor);
    if (deleteButton)
        connectSignal(deleteButton, "clicked", callback, nullptr, nullptr, 1); // G_CONNECT_AFTER

    // Keep Swappy's normal Copy handler first: it serialises the rendered
    // buffer as PNG and writes those bytes to the clipboard. Copy and Save
    // both finish synchronously, so closing afterwards cannot race the output.
    if (void* copyButton = getObject(builder, "copy"))
        connectSignal(copyButton, "clicked", callback, nullptr, nullptr, 1); // G_CONNECT_AFTER
    if (void* saveButton = getObject(builder, "save"))
        connectSignal(saveButton, "clicked", callback, nullptr, nullptr, 1); // G_CONNECT_AFTER

    actionsWired = true;
}

} // namespace

extern "C" guint gtk_builder_add_from_resource(GtkBuilder* builder, const char* resourcePath, GError** error) {
    const auto addFromResource = loadNext<BuilderAddFromResource>("gtk_builder_add_from_resource");
    if (!addFromResource)
        return 0;

    const guint result = addFromResource(builder, resourcePath, error);
    if (result != 0 && resourcePath && std::strstr(resourcePath, "swappy.glade"))
        customiseUi(builder);
    return result;
}

extern "C" void gtk_builder_connect_signals(GtkBuilder* builder, void* userData) {
    const auto connectSignals = loadNext<BuilderConnectSignals>("gtk_builder_connect_signals");
    if (!connectSignals)
        return;

    connectSignals(builder, userData);
    if (builder == swappyBuilder)
        wireActions(builder);
}

extern "C" gboolean g_key_file_get_boolean(GKeyFile* keyFile, const char* groupName, const char* key, GError** error) {
    if (key) {
        // The adapter closes only after Copy/Save completes, keeping cleanup
        // ordering deterministic regardless of the user's Swappy config.
        if (std::strcmp(key, "early_exit") == 0)
            return 0;
        if (std::strcmp(key, "auto_save") == 0)
            return 0;
    }

    const auto getBoolean = loadNext<KeyFileGetBoolean>("g_key_file_get_boolean");
    return getBoolean ? getBoolean(keyFile, groupName, key, error) : 0;
}
