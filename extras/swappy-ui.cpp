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
using BoxNew = void* (*)(int, int);
using BoxPackStart = void (*)(void*, void*, gboolean, gboolean, guint);
using BoxSetSpacing = void (*)(void*, int);
using ButtonSetAlwaysShowImage = void (*)(void*, gboolean);
using ButtonSetImagePosition = void (*)(void*, int);
using ButtonSetLabel = void (*)(void*, const char*);
using ButtonGetImage = void* (*)(void*);
using ContainerGetChildren = void* (*)(void*);
using ContainerRemove = void (*)(void*, void*);
using ListFree = void (*)(void*);
using ObjectRef = void* (*)(void*);
using ObjectUnref = void (*)(void*);
using OrientableSetOrientation = void (*)(void*, int);
using PanedPack = void (*)(void*, void*, gboolean, gboolean);
using ImageSetFromIconName = void (*)(void*, const char*, int);
using KeyFileGetBoolean = gboolean (*)(GKeyFile*, const char*, const char*, GError**);
using SignalConnectData = gulong (*)(void*, const char*, void (*)(), void*, void (*)(void*, void*), int);
using SignalHandlersDisconnectMatched = guint (*)(void*, int, guint, unsigned int, void*, void*, void*);
using StyleContextAddClass = void (*)(void*, const char*);
using ToggleButtonGetActive = gboolean (*)(void*);
using WidgetDestroy = void (*)(void*);
using WidgetGetParent = void* (*)(void*);
using WidgetGetStyleContext = void* (*)(void*);
using WidgetHide = void (*)(void*);
using WidgetSetMarginBottom = void (*)(void*, int);
using WidgetSetTooltipText = void (*)(void*, const char*);
using WidgetShow = void (*)(void*);

template <typename T> T loadNext(const char* name) {
    return std::bit_cast<T>(dlsym(RTLD_NEXT, name));
}

void* editorWindow;
WidgetDestroy destroyWidget;
GtkBuilder* swappyBuilder;
bool actionsWired;
bool editingEnabled;

struct ListNode {
    void* data;
    ListNode* next;
    ListNode* previous;
};

void discardTemporaryCapture() {
    if (const char* path = std::getenv("CAELESTIA_SCREENSHOT_PATH"))
        std::remove(path);
}

void closeEditor(void*, void*) {
    discardTemporaryCapture();
    if (editorWindow && destroyWidget)
        destroyWidget(editorWindow);
}

gboolean blockDrawingUntilEnabled(void*, void*, void*) {
    return editingEnabled ? 0 : 1;
}

void updateEditingState(void* button, void*) {
    const auto getActive = loadNext<ToggleButtonGetActive>("gtk_toggle_button_get_active");
    editingEnabled = getActive && getActive(button);
}

void moveEditingToolsToBottom(GtkBuilder* builder) {
    const auto getObject = loadNext<BuilderGetObject>("gtk_builder_get_object");
    const auto getParent = loadNext<WidgetGetParent>("gtk_widget_get_parent");
    const auto setOrientation = loadNext<OrientableSetOrientation>("gtk_orientable_set_orientation");
    const auto remove = loadNext<ContainerRemove>("gtk_container_remove");
    const auto ref = loadNext<ObjectRef>("g_object_ref");
    const auto unref = loadNext<ObjectUnref>("g_object_unref");
    const auto packFirst = loadNext<PanedPack>("gtk_paned_pack1");
    const auto packSecond = loadNext<PanedPack>("gtk_paned_pack2");
    const auto newBox = loadNext<BoxNew>("gtk_box_new");
    const auto packStart = loadNext<BoxPackStart>("gtk_box_pack_start");
    const auto setSpacing = loadNext<BoxSetSpacing>("gtk_box_set_spacing");
    const auto getChildren = loadNext<ContainerGetChildren>("gtk_container_get_children");
    const auto freeList = loadNext<ListFree>("g_list_free");
    const auto hide = loadNext<WidgetHide>("gtk_widget_hide");
    const auto show = loadNext<WidgetShow>("gtk_widget_show");
    const auto setMarginBottom = loadNext<WidgetSetMarginBottom>("gtk_widget_set_margin_bottom");
    const auto getStyleContext = loadNext<WidgetGetStyleContext>("gtk_widget_get_style_context");
    const auto addClass = loadNext<StyleContextAddClass>("gtk_style_context_add_class");
    if (!getObject || !getParent || !setOrientation || !remove || !ref || !unref || !packFirst || !packSecond ||
        !newBox || !packStart || !setSpacing || !getChildren || !freeList || !hide || !show)
        return;

    void* tools = getObject(builder, "painting-box");
    void* canvas = getObject(builder, "painting-area");
    if (!tools || !canvas)
        return;

    void* canvasContainer = getParent(canvas);
    void* split = getParent(tools);
    if (!canvasContainer || !split)
        return;

    // Reverse Swappy's horizontal split: canvas first, compact tool dock below.
    ref(tools);
    ref(canvasContainer);
    remove(split, tools);
    remove(split, canvasContainer);
    setOrientation(split, 1); // GTK_ORIENTATION_VERTICAL
    packFirst(split, canvasContainer, 1, 0);
    packSecond(split, tools, 0, 0);
    unref(canvasContainer);
    unref(tools);

    // Replace the tall sidebar stack with two concise horizontal tool rows.
    auto parentOf = [&](const char* id) -> void* {
        if (void* child = getObject(builder, id))
            return getParent(child);
        return nullptr;
    };
    void* modeRow = parentOf("brush");
    void* colourRow = getObject(builder, "brush-box");
    void* lineRow = parentOf("minus-button");
    void* textRow = parentOf("text-minus-button");
    void* transparencyRow = parentOf("transparency-minus-button");
    void* optionsRow = parentOf("fill-shape-toggle-button");
    if (!modeRow || !colourRow || !lineRow || !textRow || !transparencyRow || !optionsRow)
        return;

    auto* children = static_cast<ListNode*>(getChildren(tools));
    if (children)
        hide(children->data); // Shortcut letters duplicate the visible tool icons.
    freeList(children);

    void* primaryRow = newBox(0, 6); // GTK_ORIENTATION_HORIZONTAL
    void* secondaryRow = newBox(0, 6);
    if (!primaryRow || !secondaryRow)
        return;

    auto moveTo = [&](void* child, void* row) {
        ref(child);
        remove(tools, child);
        if (setMarginBottom)
            setMarginBottom(child, 0);
        packStart(row, child, 0, 0, 0);
        unref(child);
    };
    moveTo(modeRow, primaryRow);
    moveTo(colourRow, primaryRow);
    moveTo(lineRow, secondaryRow);
    moveTo(textRow, secondaryRow);
    moveTo(transparencyRow, secondaryRow);
    moveTo(optionsRow, secondaryRow);

    setOrientation(tools, 1); // GTK_ORIENTATION_VERTICAL
    setSpacing(tools, 4);
    packStart(tools, primaryRow, 0, 0, 0);
    packStart(tools, secondaryRow, 0, 0, 0);
    if (getStyleContext && addClass) {
        addClass(getStyleContext(primaryRow), "caelestia-tool-row");
        addClass(getStyleContext(secondaryRow), "caelestia-tool-row");
    }
    show(primaryRow);
    show(secondaryRow);
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
    moveEditingToolsToBottom(builder);
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

        const auto connectSignal = loadNext<SignalConnectData>("g_signal_connect_data");
        if (connectSignal)
            connectSignal(editButton, "toggled", reinterpret_cast<void (*)()>(updateEditingState), nullptr, nullptr, 0);
    }

    // Swappy starts in brush mode even with its tools hidden. Consume canvas
    // pointer events until the user explicitly activates the pencil button.
    editingEnabled = false;
    if (void* canvas = getObject(builder, "painting-area")) {
        const auto connectSignal = loadNext<SignalConnectData>("g_signal_connect_data");
        if (connectSignal) {
            const auto blocker = reinterpret_cast<void (*)()>(blockDrawingUntilEnabled);
            connectSignal(canvas, "button-press-event", blocker, nullptr, nullptr, 0);
            connectSignal(canvas, "button-release-event", blocker, nullptr, nullptr, 0);
            connectSignal(canvas, "motion-notify-event", blocker, nullptr, nullptr, 0);
        }
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
        if (std::strcmp(key, "show_panel") == 0)
            return 0;
    }

    const auto getBoolean = loadNext<KeyFileGetBoolean>("g_key_file_get_boolean");
    return getBoolean ? getBoolean(keyFile, groupName, key, error) : 0;
}
