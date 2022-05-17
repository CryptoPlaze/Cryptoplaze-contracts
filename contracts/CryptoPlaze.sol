// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./SVGHandler.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Make the create function payable and require one dollar

contract CryptoPlaze is ERC721URIStorage, Ownable {
    enum SaleStatus {
        Undefined,
        ForSale,
        NotForSale
    }
    struct PieceData {
        uint256 lastModified;
        string hexCode;
        SaleStatus status;
        uint256 price;
        address seller;
    }

    AggregatorV3Interface internal priceFeed;
    uint256 public initialPrice;
    uint256 public tokenCounter;
    uint256 internal blockSpan;
    uint256 private constant MAX_SUPPLY = 1000000;
    mapping(uint256 => PieceData) public cryptoPlazePiece;

    event PieceCreated(uint256 indexed tokenId, string tokenURI);
    event PieceColorChanged(uint256 indexed tokenId, string tokenURI);
    event PieceListedForSale(address seller, uint256 tokenId, uint256 price);
    event PieceStolen(address from, address by, uint256 tokenId);

    event PieceSaleCompleted(
        uint256 tokenId,
        uint256 price,
        address buyer,
        address seller
    );
    event PieceSaleCanceled(uint256 tokenId, address seller);

    constructor() ERC721("Crypto Plaze", "PLAZE") {
        tokenCounter = 0;
        initialPrice = 1 ether;
        blockSpan = 30;
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function changeBlockSpan(uint256 newBlockSpan) public {
        blockSpan = newBlockSpan;
    }

    function changeInitialPrice(uint256 newPrice) public {
        require(msg.sender == owner(), "Only owner can change the price");
        initialPrice = newPrice;
    }

    function changeColor(uint256 tokenId, string memory hexCode) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only owner can change the color"
        );
        require(SVGHandler.isValidHex(hexCode), "Hex 3 or 6 chr long");
        string memory svg = SVGHandler.createSVG(hexCode);

        string memory imageURI = SVGHandler.svgToImageURI(svg);
        _setTokenURI(tokenId, SVGHandler.formatTokenURI(imageURI, tokenId));

        cryptoPlazePiece[tokenId].lastModified = block.number;
        cryptoPlazePiece[tokenId].hexCode = SVGHandler.formatHex(hexCode);

        emit PieceColorChanged(tokenCounter, svg);
    }

    function create(string memory hexCode, uint256 tokenId) external payable {
        // Check if max amount of tokens is already created
        require(
            tokenCounter < MAX_SUPPLY && tokenId > 0 && tokenId < MAX_SUPPLY,
            "TokenId must be 1 - 1 mil"
        );
        require(
            cryptoPlazePiece[tokenId].status == SaleStatus.Undefined,
            "That piece was already minted"
        );
        require(SVGHandler.isValidHex(hexCode), "Hex must be 3 or 6 chr long!");

        require(msg.value >= initialPrice, "Insufficient payment");

        string memory svg = SVGHandler.createSVG(hexCode);
        tokenCounter = tokenCounter + 1;
        _safeMint(msg.sender, tokenId);
        string memory imageURI = SVGHandler.svgToImageURI(svg);
        _setTokenURI(
            tokenId,
            SVGHandler.formatTokenURI(imageURI, tokenCounter)
        );

        cryptoPlazePiece[tokenId] = PieceData(
            block.number,
            SVGHandler.formatHex(hexCode),
            SaleStatus.NotForSale,
            0,
            msg.sender
        );

        payable(owner()).transfer(initialPrice);
        payable(msg.sender).transfer(msg.value - initialPrice);
        emit PieceCreated(tokenId, svg);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        cryptoPlazePiece[tokenId].lastModified = block.number;
        super._afterTokenTransfer(from, to, tokenId);
    }

    function stealThePiece(uint256 tokenId) external {
        // Add + 30 days
        require(
            block.number > cryptoPlazePiece[tokenId].lastModified + blockSpan,
            "Can't steal right now."
        );
        address victim = ownerOf(tokenId);

        require(msg.sender != victim, "Cannot steal from yourself");

        _transfer(victim, msg.sender, tokenId);

        PieceData storage piece = cryptoPlazePiece[tokenId];
        piece.lastModified = block.number;
        piece.seller = msg.sender;
        piece.status = SaleStatus.NotForSale;

        emit PieceStolen(victim, msg.sender, tokenId);
    }

    function setForSale(uint256 tokenId, uint256 price) external {
        IERC721(address(this)).transferFrom(msg.sender, address(this), tokenId);
        cryptoPlazePiece[tokenId].status = SaleStatus.ForSale;
        cryptoPlazePiece[tokenId].price = price;

        emit PieceListedForSale(msg.sender, tokenId, price);
    }

    function buyThePiece(uint256 tokenId) external payable {
        PieceData storage piece = cryptoPlazePiece[tokenId];

        require(msg.sender != piece.seller, "Seller cannot be buyer");
        require(
            piece.status == SaleStatus.ForSale,
            "The token is not for sale"
        );

        require(msg.value >= piece.price, "Insufficient payment");
        address oldOwner = piece.seller;
        IERC721(address(this)).transferFrom(address(this), msg.sender, tokenId);

        uint256 fee = piece.price / 100;
        payable(owner()).transfer(fee);
        payable(piece.seller).transfer((piece.price - fee));
        piece.seller = msg.sender;
        emit PieceSaleCompleted(tokenId, piece.price, msg.sender, oldOwner);
    }

    function cancelSale(uint256 tokenId) public {
        PieceData storage piece = cryptoPlazePiece[tokenId];

        require(msg.sender == piece.seller, "Only seller can cancel sale");
        require(
            piece.status == SaleStatus.ForSale,
            "The token is not for sale"
        );

        piece.status = SaleStatus.NotForSale;

        IERC721(address(this)).transferFrom(address(this), msg.sender, tokenId);

        emit PieceSaleCanceled(tokenId, msg.sender);
    }
}
