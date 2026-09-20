# classes2.dex

.class final Landroid/media/MediaRouter2$PackageNameUserHandlePair;
.super Ljava/lang/Record;
.source "MediaRouter2.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Landroid/media/MediaRouter2;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "PackageNameUserHandlePair"
.end annotation

.annotation system Ldalvik/annotation/Record;
    componentAnnotationVisibilities = {
        {},
        {}
    }
    componentAnnotations = {
        {},
        {}
    }
    componentNames = {
        "packageName",
        "user"
    }
    componentSignatures = {
        null,
        null
    }
    componentTypes = {
        Ljava/lang/String;,
        Landroid/os/UserHandle;
    }
.end annotation


# instance fields
.field private final blacklist packageName:Ljava/lang/String;

.field private final blacklist user:Landroid/os/UserHandle;


# direct methods
.method private synthetic blacklist $record$equals(Ljava/lang/Object;)Z
    .registers 5

    const/4 v0, 0x0

    if-nez p1, :cond_4

    return v0

    :cond_4
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {p1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v2

    if-eq v1, v2, :cond_f

    return v0

    :cond_f
    invoke-direct {p0}, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object v0

    check-cast p1, Landroid/media/MediaRouter2$PackageNameUserHandlePair;

    invoke-direct {p1}, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object p1

    invoke-static {v0, p1}, Ljava/util/Arrays;->equals([Ljava/lang/Object;[Ljava/lang/Object;)Z

    move-result p1

    return p1
.end method

.method private synthetic blacklist $record$getFieldsAsObjects()[Ljava/lang/Object;
    .registers 3

    iget-object v0, p0, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->packageName:Ljava/lang/String;

    iget-object v1, p0, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->user:Landroid/os/UserHandle;

    filled-new-array {v0, v1}, [Ljava/lang/Object;

    move-result-object v0

    return-object v0
.end method

.method private constructor blacklist <init>(Ljava/lang/String;Landroid/os/UserHandle;)V
    .registers 3
    .param p1, "packageName"  # Ljava/lang/String;
    .param p2, "user"  # Landroid/os/UserHandle;
    .annotation system Ldalvik/annotation/MethodParameters;
        accessFlags = {
            0x0,
            0x0
        }
        names = {
            "packageName",
            "user"
        }
    .end annotation

    .line 138
    invoke-direct {p0}, Ljava/lang/Record;-><init>()V

    iput-object p1, p0, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->packageName:Ljava/lang/String;

    iput-object p2, p0, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->user:Landroid/os/UserHandle;

    return-void
.end method

.method synthetic constructor blacklist <init>(Ljava/lang/String;Landroid/os/UserHandle;Landroid/media/MediaRouter2$PackageNameUserHandlePair-IA;)V
    .registers 4

    invoke-direct {p0, p1, p2}, Landroid/media/MediaRouter2$PackageNameUserHandlePair;-><init>(Ljava/lang/String;Landroid/os/UserHandle;)V

    return-void
.end method


# virtual methods
.method public final whitelist test-api equals(Ljava/lang/Object;)Z
    .registers 2

    .line 138
    invoke-direct {p0, p1}, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->$record$equals(Ljava/lang/Object;)Z

    move-result p1

    return p1
.end method

.method public final whitelist test-api hashCode()I
    .registers 3

    .line 138
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    invoke-direct {p0}, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/app/ApplicationPackageManager$HasSystemFeatureQuery$$ExternalSyntheticRecord1;->m(Ljava/lang/Class;[Ljava/lang/Object;)I

    move-result v0

    return v0
.end method

.method public blacklist packageName()Ljava/lang/String;
    .registers 2

    .line 138
    iget-object v0, p0, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->packageName:Ljava/lang/String;

    return-object v0
.end method

.method public final whitelist test-api toString()Ljava/lang/String;
    .registers 4

    .line 138
    invoke-direct {p0}, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object v0

    const-class v1, Landroid/media/MediaRouter2$PackageNameUserHandlePair;

    const-string v2, "packageName;user"

    invoke-static {v0, v1, v2}, Landroid/app/ApplicationPackageManager$HasSystemFeatureQuery$$ExternalSyntheticRecord0;->m([Ljava/lang/Object;Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    return-object v0
.end method

.method public blacklist user()Landroid/os/UserHandle;
    .registers 2

    .line 138
    iget-object v0, p0, Landroid/media/MediaRouter2$PackageNameUserHandlePair;->user:Landroid/os/UserHandle;

    return-object v0
.end method
