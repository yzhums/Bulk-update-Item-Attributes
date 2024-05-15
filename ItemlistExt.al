pageextension 50115 ItemlistExt extends "Item List"
{
    actions
    {
        addafter(CopyItem)
        {
            action(BulkEditAttrubute)
            {
                Caption = 'Bulk Edit Attributes';
                Image = Edit;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Item: Record Item;
                    ItemAttributesValueList: Page "ZY Item Attributes Value List";
                    SelectionFilterManagement: Codeunit SelectionFilterManagement;
                    RecRef: RecordRef;
                begin
                    Item.Reset();
                    CurrPage.SetSelectionFilter(Item);
                    RecRef.GetTable(Item);
                    ItemAttributesValueList.GetSelectionFilter(SelectionFilterManagement.GetSelectionFilter(RecRef, Item.FieldNo("No.")));
                    ItemAttributesValueList.RunModal();
                    CurrPage.ItemAttributesFactBox.PAGE.LoadItemAttributesData(Rec."No.");
                end;

            }
        }
    }
}


page 50103 "ZY Item Attributes Value List"
{
    Caption = 'Item Attributes Values';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Item Attribute Value Selection";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(ItemFilters)
            {
                ShowCaption = false;
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Item Filter';
                    Editable = false;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Attribute';
                    TableRelation = "Item Attribute".Name where(Blocked = const(false));
                    ToolTip = 'Specifies the item attribute.';

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
                        ItemAttribute: Record "Item Attribute";
                        Item: Record Item;
                    begin
                        Item.Reset();
                        Item.SetFilter("No.", ItemFilter);
                        if Item.FindSet() then
                            repeat
                                RelatedRecordCode := '';
                                RelatedRecordCode := Item."No.";
                                if xRec."Attribute Name" <> '' then begin
                                    xRec.FindItemAttributeByName(ItemAttribute);
                                    DeleteItemAttributeValueMapping(ItemAttribute.ID);
                                end;
                                if not Rec.FindAttributeValue(ItemAttributeValue) then
                                    Rec.InsertItemAttributeValue(ItemAttributeValue, Rec);
                                if ItemAttributeValue.Get(ItemAttributeValue."Attribute ID", ItemAttributeValue.ID) then begin
                                    if not ItemAttributeValueMapping.Get(Database::Item, RelatedRecordCode, ItemAttributeValue."Attribute ID") then begin
                                        ItemAttributeValueMapping.Reset();
                                        ItemAttributeValueMapping.Init();
                                        ItemAttributeValueMapping."Table ID" := Database::Item;
                                        ItemAttributeValueMapping."No." := RelatedRecordCode;
                                        ItemAttributeValueMapping."Item Attribute ID" := ItemAttributeValue."Attribute ID";
                                        ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
                                        ItemAttributeValueMapping.Insert();
                                    end;
                                end;
                            until Item.Next() = 0;
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    TableRelation = if ("Attribute Type" = const(Option)) "Item Attribute Value".Value where("Attribute ID" = field("Attribute ID"),
                                                                                                            Blocked = const(false));
                    ToolTip = 'Specifies the value of the item attribute.';

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
                        ItemAttribute: Record "Item Attribute";
                        Item: Record Item;
                    begin
                        Item.Reset();
                        Item.SetFilter("No.", ItemFilter);
                        if Item.FindSet() then
                            repeat
                                RelatedRecordCode := '';
                                RelatedRecordCode := Item."No.";
                                if not Rec.FindAttributeValue(ItemAttributeValue) then
                                    Rec.InsertItemAttributeValue(ItemAttributeValue, Rec);
                                ItemAttributeValueMapping.Reset();
                                ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
                                ItemAttributeValueMapping.SetRange("No.", RelatedRecordCode);
                                ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttributeValue."Attribute ID");
                                if ItemAttributeValueMapping.FindFirst() then begin
                                    ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
                                    ItemAttributeValueMapping.Modify();
                                end;

                                ItemAttribute.Get(Rec."Attribute ID");
                                if ItemAttribute.Type <> ItemAttribute.Type::Option then
                                    if Rec.FindAttributeValueFromRecord(ItemAttributeValue, xRec) then
                                        if not ItemAttributeValue.HasBeenUsed() then
                                            ItemAttributeValue.Delete();
                            until Item.Next() = 0;
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
            }
        }
    }
    var
        ItemFilter: Code[250];

    trigger OnOpenPage()
    begin
        CurrPage.Editable(true);
    end;

    protected var
        RelatedRecordCode: Code[20];

    local procedure DeleteItemAttributeValueMapping(AttributeToDeleteID: Integer)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", RelatedRecordCode);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeToDeleteID);
        if ItemAttributeValueMapping.FindFirst() then begin
            ItemAttributeValueMapping.Delete();
        end;

        ItemAttribute.Get(AttributeToDeleteID);
        ItemAttribute.RemoveUnusedArbitraryValues();
    end;

    procedure GetSelectionFilter(ItemPageFilter: Code[250])
    begin
        ItemFilter := '';
        ItemFilter := ItemPageFilter;
    end;
}
