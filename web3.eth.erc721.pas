{******************************************************************************}
{                                                                              }
{                                  Delphereum                                  }
{                                                                              }
{             Copyright(c) 2019 Stefan van As <svanas@runbox.com>              }
{           Github Repository <https://github.com/svanas/delphereum>           }
{                                                                              }
{   Distributed under Creative Commons NonCommercial (aka CC BY-NC) license.   }
{                                                                              }
{******************************************************************************}

unit web3.eth.erc721;

{$I web3.inc}

interface

uses
  // Delphi
  System.SysUtils,
  System.Threading,
  // web3
  web3,
  web3.eth,
  web3.eth.contract,
  web3.eth.crypto,
  web3.eth.logs,
  web3.eth.types,
  web3.types;

type
  // https://eips.ethereum.org/EIPS/eip-721
  IERC721 = interface
    // Count all NFTs assigned to an owner
    procedure BalanceOf(
      owner    : TAddress;        // An address for whom to query the balance
      callback : TASyncQuantity); // The number of NFTs owned by `owner`, possibly zero
    // Find the owner of an NFT
    procedure OwnerOf(
      tokenId  : UInt64;          // The identifier for an NFT
      callback : TASyncAddress);  // The address of the owner of the NFT
    // Transfers the ownership of an NFT from one address to another address
    // Throws...
    // 1) if `from` is not the current owner, or
    // 2) if `to` is the zero address, or
    // 3) if `tokenId` is not a valid NFT, or
    // 4) unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    procedure SafeTransferFrom(
      from     : TPrivateKey;     // The current owner of the NFT
      &to      : TAddress;        // The new owner
      tokenId  : UInt64;          // The NFT to transfer
      callback : TASyncReceipt);
    // Transfers the ownership of an NFT from one address to another address
    // THE CALLER IS RESPONSIBLE TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING
    // NFTs OR ELSE THEY MAY BE PERMANENTLY LOST
    procedure TransferFrom(
      from     : TPrivateKey;     // The current owner of the NFT
      &to      : TAddress;        // The new owner
      tokenId  : UInt64;          // The NFT to transfer
      callback : TASyncReceipt);
    // Change or reaffirm the approved address for an NFT
    procedure Approve(
      owner    : TPrivateKey;     // The current owner of the NFT
      spender  : TAddress;        // The new approved NFT controller
      tokenId  : UInt64;          // The NFT to approve
      callback : TASyncReceipt);
    // Change or reaffirm the approved address for an NFT
    procedure SetApprovalForAll(
      owner    : TPrivateKey;     // The current owner of the NFT
      &operator: TAddress;        // Address to add to the set of authorized operators
      approved : Boolean;         // True if the operator is approved, false to revoke approval
      callback : TASyncReceipt);
    // Get the approved address for a single NFT
    procedure GetApproved(
      tokenId  : UInt64;          // The NFT to find the approved address for
      callback : TASyncAddress);  // The approved address for this NFT, or the zero address if there is none
    // Query if an address is an authorized operator for another address
    procedure IsApprovedForAll(
      owner    : TAddress;        // The address that owns the NFTs
      &operator: TAddress;        // The address that acts on behalf of the owner
      callback : TASyncBoolean);  // True if `operator` is an approved operator for `owner`, false otherwise
  end;

  IERC721Metadata = interface
    // A descriptive name for a collection of NFTs in this contract
    procedure Name(callback: TASyncString);
    // An abbreviated name for NFTs in this contract
    procedure Symbol(callback: TASyncString);
    // A distinct Uniform Resource Identifier (URI) for a given asset.
    // The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
    procedure TokenURI(tokenId: UInt64; callback: TASyncString);
  end;

  IERC721Enumerable = interface
    // Count NFTs tracked by this contract
    procedure TotalSupply(callback: TASyncQuantity);
    // Enumerate valid NFTs
    procedure TokenByIndex(
      index   : UInt64;          // A counter less than `totalSupply()`
      callback: TASyncQuantity); // The token identifier for the `index`th NFT
    // Enumerate NFTs assigned to an owner
    procedure TokenOfOwnerByIndex(
      owner   : TAddress;        // An address where we are interested in NFTs owned by them
      index   : UInt64;          // A counter less than `balanceOf(_owner)`
      callback: TASyncQuantity); // The token identifier for the `index`th NFT assigned to `owner`
  end;

  // This emits when ownership of any NFT changes by any mechanism.
  TOnTransfer = reference to procedure(
    Sender : TObject;
    From   : TAddress;
    &To    : TAddress;
    TokenId: UInt64);

  // This emits when the approved address for an NFT is changed or
  // reaffirmed. The zero address indicates there is no approved address.
  TOnApproval = reference to procedure(
    Sender : TObject;
    Owner  : TAddress;
    Spender: TAddress;
    TokenId: UInt64);

  // This emits when an operator is enabled or disabled for an owner.
  // The operator can manage all NFTs of the owner.
  TOnApprovalForAll = reference to procedure(
    Sender   : TObject;
    Owner    : TAddress;
    &Operator: TAddress;
    Approved : Boolean);

  TERC721 = class(TCustomContract, IERC721, IERC721Metadata, IERC721Enumerable)
  strict private
    FTask: ITask;
    FOnTransfer: TOnTransfer;
    FOnApproval: TOnApproval;
    FOnApprovalForAll: TOnApprovalForAll;
    procedure SetOnTransfer(Value: TOnTransfer);
    procedure SetOnApproval(Value: TOnApproval);
    procedure SetOnApprovalForAll(Value: TOnApprovalForAll);
  protected
    procedure WatchOrStop; virtual;
  public
    constructor Create(aClient: TWeb3; aContract: TAddress); override;
    destructor  Destroy; override;
    // IERC721
    procedure BalanceOf(
      owner    : TAddress;
      callback : TASyncQuantity);
    procedure OwnerOf(
      tokenId  : UInt64;
      callback : TASyncAddress);
    procedure SafeTransferFrom(
      from     : TPrivateKey;
      &to      : TAddress;
      tokenId  : UInt64;
      callback : TASyncReceipt);
    procedure TransferFrom(
      from     : TPrivateKey;
      &to      : TAddress;
      tokenId  : UInt64;
      callback : TASyncReceipt);
    procedure Approve(
      owner    : TPrivateKey;
      spender  : TAddress;
      tokenId  : UInt64;
      callback : TASyncReceipt);
    procedure SetApprovalForAll(
      owner    : TPrivateKey;
      &operator: TAddress;
      approved : Boolean;
      callback : TASyncReceipt);
    procedure GetApproved(
      tokenId  : UInt64;
      callback : TASyncAddress);
    procedure IsApprovedForAll(
      owner    : TAddress;
      &operator: TAddress;
      callback : TASyncBoolean);
    // IERC721Metadata
    procedure Name(callback: TASyncString);
    procedure Symbol(callback: TASyncString);
    procedure TokenURI(tokenId: UInt64; callback: TASyncString);
    // IERC721Enumerable
    procedure TotalSupply(callback: TASyncQuantity);
    procedure TokenByIndex(index: UInt64; callback: TASyncQuantity);
    procedure TokenOfOwnerByIndex(owner: TAddress; index: UInt64; callback: TASyncQuantity);
    // events
    property OnTransfer: TOnTransfer read FOnTransfer write SetOnTransfer;
    property OnApproval: TOnApproval read FOnApproval write SetOnApproval;
    property OnApprovalForAll: TOnApprovalForAll read FOnApprovalForAll write SetOnApprovalForAll;
  end;

implementation

{ TERC721}

constructor TERC721.Create(aClient: TWeb3; aContract: TAddress);
begin
  inherited Create(aClient, aContract);

  FTask := web3.eth.logs.get(aClient, aContract,
    procedure(log: TLog)
    begin
      if Assigned(FOnTransfer) then
        if log.isEvent('Transfer(address,address,uint256)') then
          FOnTransfer(Self,
                      TAddress.New(log.Topic[1]),
                      TAddress.New(log.Topic[2]), toInt(log.Topic[3]));
      if Assigned(FOnApproval) then
        if log.isEvent('Approval(address,address,uint256)') then
          FOnApproval(Self,
                      TAddress.New(log.Topic[1]),
                      TAddress.New(log.Topic[2]), toInt(log.Topic[3]));
      if Assigned(FOnApprovalForAll) then
        if log.isEvent('ApprovalForAll(address,address,bool)') then
          FOnApprovalForAll(Self,
                            TAddress.New(log.Topic[1]),
                            TAddress.New(log.Topic[2]), toBool(log.Data[0]));
    end);
end;

destructor TERC721.Destroy;
begin
  if FTask.Status = TTaskStatus.Running then
    FTask.Cancel;
  inherited Destroy;
end;

procedure TERC721.SetOnTransfer(Value: TOnTransfer);
begin
  FOnTransfer := Value;
  WatchOrStop;
end;

procedure TERC721.SetOnApproval(Value: TOnApproval);
begin
  FOnApproval := Value;
  WatchOrStop;
end;

procedure TERC721.SetOnApprovalForAll(Value: TOnApprovalForAll);
begin
  FOnApprovalForAll := Value;
  WatchOrStop;
end;

procedure TERC721.WatchOrStop;
begin
  if Assigned(FOnTransfer)
  or Assigned(FOnApproval)
  or Assigned(FOnApprovalForAll) then
  begin
    if FTask.Status <> TTaskStatus.Running then
      FTask.Start;
    EXIT;
  end;
  if FTask.Status = TTaskStatus.Running then
    FTask.Cancel;
end;

procedure TERC721.BalanceOf(owner: TAddress; callback: TASyncQuantity);
begin
  web3.eth.call(Client, Contract, 'balanceOf(address)', [owner], callback);
end;

procedure TERC721.OwnerOf(tokenId: UInt64; callback: TASyncAddress);
begin
  web3.eth.call(Client, Contract, 'ownerOf(uint256)', [tokenId], procedure(const hex: string; err: Exception)
  begin
    if Assigned(err) then
      callback('', err)
    else
      callback(TAddress.New(hex), nil)
  end);
end;

procedure TERC721.SafeTransferFrom(
  from    : TPrivateKey;
  &to     : TAddress;
  tokenId : UInt64;
  callback: TASyncReceipt);
begin
  web3.eth.write(Client, from, Contract,
    'safeTransferFrom(address,address,uint256)',
    [AddressFromPrivateKey(PrivateKeyFromHex(from)), &to, tokenId], callback);
end;

procedure TERC721.TransferFrom(
  from    : TPrivateKey;
  &to     : TAddress;
  tokenId : UInt64;
  callback: TASyncReceipt);
begin
  web3.eth.write(Client, from, Contract,
    'transferFrom(address,address,uint256)',
    [AddressFromPrivateKey(PrivateKeyFromHex(from)), &to, tokenId], callback);
end;

procedure TERC721.Approve(
  owner   : TPrivateKey;
  spender : TAddress;
  tokenId : UInt64;
  callback: TASyncReceipt);
begin
  web3.eth.write(Client, owner, Contract, 'approve(address,uint256)', [spender, tokenId], callback);
end;

procedure TERC721.SetApprovalForAll(
  owner    : TPrivateKey;
  &operator: TAddress;
  approved : Boolean;
  callback : TASyncReceipt);
begin
  web3.eth.write(Client, owner, Contract, 'setApprovalForAll(address,bool)', [&operator, approved], callback);
end;

procedure TERC721.GetApproved(tokenId: UInt64; callback: TASyncAddress);
begin
  web3.eth.call(Client, Contract, 'getApproved(uint256)', [tokenId], procedure(const hex: string; err: Exception)
  begin
    if Assigned(err) then
      callback('', err)
    else
      callback(TAddress.New(hex), nil)
  end);
end;

procedure TERC721.IsApprovedForAll(
  owner    : TAddress;
  &operator: TAddress;
  callback : TASyncBoolean);
begin
  web3.eth.call(Client, Contract, 'isApprovedForAll(address,address)', [owner, &operator], callback);
end;

procedure TERC721.Name(callback: TASyncString);
begin
  web3.eth.call(Client, Contract, 'name()', [], procedure(tup: TTuple; err: Exception)
  begin
    if Assigned(err) then
      callback('', err)
    else
      callback(tup.ToString, nil);
  end);
end;

procedure TERC721.Symbol(callback: TASyncString);
begin
  web3.eth.call(Client, Contract, 'symbol()', [], procedure(tup: TTuple; err: Exception)
  begin
    if Assigned(err) then
      callback('', err)
    else
      callback(tup.ToString, nil);
  end);
end;

procedure TERC721.TokenURI(tokenId: UInt64; callback: TASyncString);
begin
  web3.eth.call(Client, Contract, 'tokenURI(uint256)', [tokenId], procedure(tup: TTuple; err: Exception)
  begin
    if Assigned(err) then
      callback('', err)
    else
      callback(tup.ToString, nil);
  end);
end;

procedure TERC721.TotalSupply(callback: TASyncQuantity);
begin
  web3.eth.call(Client, Contract, 'totalSupply()', [], callback);
end;

procedure TERC721.TokenByIndex(index: UInt64; callback: TASyncQuantity);
begin
  web3.eth.call(Client, Contract, 'tokenByIndex(uint256)', [index], callback);
end;

procedure TERC721.TokenOfOwnerByIndex(owner: TAddress; index: UInt64; callback: TASyncQuantity);
begin
  web3.eth.call(Client, Contract, 'tokenOfOwnerByIndex(address,uint256)', [owner, index], callback);
end;

end.