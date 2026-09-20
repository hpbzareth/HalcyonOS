# classes2.dex

.class public final Landroid/hardware/input/PhysicalKeyLayout$EnterKey;
.super Ljava/lang/Record;
.source "PhysicalKeyLayout.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Landroid/hardware/input/PhysicalKeyLayout;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "EnterKey"
.end annotation

.annotation system Ldalvik/annotation/Record;
    componentAnnotationVisibilities = {
        {},
        {},
        {},
        {}
    }
    componentAnnotations = {
        {},
        {},
        {},
        {}
    }
    componentNames = {
        "row",
        "column",
        "topKeyWeight",
        "bottomKeyWeight"
    }
    componentSignatures = {
        null,
        null,
        null,
        null
    }
    componentTypes = {
        I,
        I,
        F,
        F
    }
.end annotation


# instance fields
.field private final blacklist bottomKeyWeight:F

.field private final blacklist column:I

.field private final blacklist row:I

.field private final blacklist topKeyWeight:F


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
    invoke-direct {p0}, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object v0

    check-cast p1, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;

    invoke-direct {p1}, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object p1

    invoke-static {v0, p1}, Ljava/util/Arrays;->equals([Ljava/lang/Object;[Ljava/lang/Object;)Z

    move-result p1

    return p1
.end method

.method private synthetic blacklist $record$getFieldsAsObjects()[Ljava/lang/Object;
    .registers 5

    iget v0, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->row:I

    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v0

    iget v1, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->column:I

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    iget v2, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->topKeyWeight:F

    invoke-static {v2}, Ljava/lang/Float;->valueOf(F)Ljava/lang/Float;

    move-result-object v2

    iget v3, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->bottomKeyWeight:F

    invoke-static {v3}, Ljava/lang/Float;->valueOf(F)Ljava/lang/Float;

    move-result-object v3

    filled-new-array {v0, v1, v2, v3}, [Ljava/lang/Object;

    move-result-object v0

    return-object v0
.end method

.method public constructor blacklist <init>(IIFF)V
    .registers 5
    .param p1, "row"  # I
    .param p2, "column"  # I
    .param p3, "topKeyWeight"  # F
    .param p4, "bottomKeyWeight"  # F
    .annotation system Ldalvik/annotation/MethodParameters;
        accessFlags = {
            0x0,
            0x0,
            0x0,
            0x0
        }
        names = {
            "row",
            "column",
            "topKeyWeight",
            "bottomKeyWeight"
        }
    .end annotation

    .line 395
    invoke-direct {p0}, Ljava/lang/Record;-><init>()V

    iput p1, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->row:I

    iput p2, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->column:I

    iput p3, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->topKeyWeight:F

    iput p4, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->bottomKeyWeight:F

    return-void
.end method


# virtual methods
.method public blacklist bottomKeyWeight()F
    .registers 2

    .line 395
    iget v0, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->bottomKeyWeight:F

    return v0
.end method

.method public blacklist column()I
    .registers 2

    .line 395
    iget v0, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->column:I

    return v0
.end method

.method public final whitelist test-api equals(Ljava/lang/Object;)Z
    .registers 2

    .line 395
    invoke-direct {p0, p1}, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->$record$equals(Ljava/lang/Object;)Z

    move-result p1

    return p1
.end method

.method public final whitelist test-api hashCode()I
    .registers 3

    .line 395
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    invoke-direct {p0}, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/app/ApplicationPackageManager$HasSystemFeatureQuery$$ExternalSyntheticRecord1;->m(Ljava/lang/Class;[Ljava/lang/Object;)I

    move-result v0

    return v0
.end method

.method public blacklist row()I
    .registers 2

    .line 395
    iget v0, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->row:I

    return v0
.end method

.method public final whitelist test-api toString()Ljava/lang/String;
    .registers 4

    .line 395
    invoke-direct {p0}, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->$record$getFieldsAsObjects()[Ljava/lang/Object;

    move-result-object v0

    const-class v1, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;

    const-string v2, "row;column;topKeyWeight;bottomKeyWeight"

    invoke-static {v0, v1, v2}, Landroid/app/ApplicationPackageManager$HasSystemFeatureQuery$$ExternalSyntheticRecord0;->m([Ljava/lang/Object;Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    return-object v0
.end method

.method public blacklist topKeyWeight()F
    .registers 2

    .line 395
    iget v0, p0, Landroid/hardware/input/PhysicalKeyLayout$EnterKey;->topKeyWeight:F

    return v0
.end method
