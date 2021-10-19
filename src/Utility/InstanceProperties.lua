-- Taken from Fusion
-- Requested by LucasMZ

return {
	ScreenGui = {
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	};

	BillboardGui = {
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	};

	SurfaceGui = {
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;

		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud;
		PixelsPerStud = 50;
	};

	Frame = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;
	};

	ScrollingFrame = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;

		ScrollBarImageColor3 = Color3.new();
	};

	TextLabel = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;

		Font = Enum.Font.SourceSans;
		Text = "";
		TextColor3 = Color3.new();
		TextSize = 14;
	};

	TextButton = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;

		AutoButtonColor = false;

		Font = Enum.Font.SourceSans;
		Text = "";
		TextColor3 = Color3.new();
		TextSize = 14;
	};

	TextBox = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;

		ClearTextOnFocus = false;

		Font = Enum.Font.SourceSans;
		Text = "";
		TextColor3 = Color3.new();
		TextSize = 14;
	};

	ImageLabel = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;
	};

	ImageButton = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;

		AutoButtonColor = false;
	};

	ViewportFrame = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;
	};

	VideoFrame = {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderColor3 = Color3.new();
		BorderSizePixel = 0;
	};

	UIGridLayout = {
		SortOrder = Enum.SortOrder.LayoutOrder;
	};

	UIListLayout = {
		SortOrder = Enum.SortOrder.LayoutOrder;
	};

	UIPageLayout = {
		Circular = true;
		SortOrder = Enum.SortOrder.LayoutOrder;
	};
}
