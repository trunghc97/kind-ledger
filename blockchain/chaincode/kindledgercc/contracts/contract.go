package contracts

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type KindLedgerContract struct {
	contractapi.Contract
}

type Campaign struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Owner       string    `json:"owner"`
	Goal        float64   `json:"goal"`
	Raised      float64   `json:"raised"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
	Donors      []Donor   `json:"donors"`
}

type Donor struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Amount    float64   `json:"amount"`
	DonatedAt time.Time `json:"donatedAt"`
}

type Donation struct {
	CampaignID string    `json:"campaignId"`
	DonorID    string    `json:"donorId"`
	DonorName  string    `json:"donorName"`
	Amount     float64   `json:"amount"`
	DonatedAt  time.Time `json:"donatedAt"`
}

func (k *KindLedgerContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	campaigns := []Campaign{
		{
			ID:          "campaign-001",
			Name:        "Hỗ trợ trẻ em nghèo",
			Description: "Quyên góp để hỗ trợ trẻ em có hoàn cảnh khó khăn",
			Owner:       "charity-org",
			Goal:        10000000,
			Raised:      0,
			Status:      "OPEN",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Donors:      []Donor{},
		},
		{
			ID:          "campaign-002",
			Name:        "Xây dựng trường học",
			Description: "Xây dựng trường học mới cho trẻ em vùng sâu vùng xa",
			Owner:       "charity-org",
			Goal:        50000000,
			Raised:      0,
			Status:      "OPEN",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Donors:      []Donor{},
		},
	}

	for _, campaign := range campaigns {
		campaignJSON, err := json.Marshal(campaign)
		if err != nil {
			return err
		}
		if err := ctx.GetStub().PutState(campaign.ID, campaignJSON); err != nil {
			return fmt.Errorf("failed to put campaign %s: %v", campaign.ID, err)
		}
	}
	return nil
}

func (k *KindLedgerContract) CreateCampaign(ctx contractapi.TransactionContextInterface, id, name, description, owner string, goal float64) error {
	exists, err := k.CampaignExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("campaign %s already exists", id)
	}
	campaign := Campaign{
		ID:          id,
		Name:        name,
		Description: description,
		Owner:       owner,
		Goal:        goal,
		Raised:      0,
		Status:      "OPEN",
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
		Donors:      []Donor{},
	}
	campaignJSON, err := json.Marshal(campaign)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, campaignJSON)
}

func (k *KindLedgerContract) Donate(ctx contractapi.TransactionContextInterface, campaignID, donorID, donorName string, amount float64) error {
	campaign, err := k.QueryCampaign(ctx, campaignID)
	if err != nil {
		return err
	}
	if campaign.Status != "OPEN" {
		return fmt.Errorf("campaign %s is not open for donations", campaignID)
	}
	campaign.Raised += amount
	campaign.UpdatedAt = time.Now()
	donor := Donor{ID: donorID, Name: donorName, Amount: amount, DonatedAt: time.Now()}
	campaign.Donors = append(campaign.Donors, donor)
	if campaign.Raised >= campaign.Goal {
		campaign.Status = "COMPLETED"
	}
	campaignJSON, err := json.Marshal(campaign)
	if err != nil {
		return err
	}
	if err := ctx.GetStub().PutState(campaignID, campaignJSON); err != nil {
		return err
	}
	donation := Donation{CampaignID: campaignID, DonorID: donorID, DonorName: donorName, Amount: amount, DonatedAt: time.Now()}
	donationKey := fmt.Sprintf("donation_%s_%s_%d", campaignID, donorID, time.Now().Unix())
	donationJSON, err := json.Marshal(donation)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(donationKey, donationJSON)
}

func (k *KindLedgerContract) QueryCampaign(ctx contractapi.TransactionContextInterface, id string) (*Campaign, error) {
	campaignJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read campaign %s: %v", id, err)
	}
	if campaignJSON == nil {
		return nil, fmt.Errorf("campaign %s does not exist", id)
	}
	var campaign Campaign
	if err := json.Unmarshal(campaignJSON, &campaign); err != nil {
		return nil, err
	}
	return &campaign, nil
}

func (k *KindLedgerContract) QueryAllCampaigns(ctx contractapi.TransactionContextInterface) ([]*Campaign, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()
	var campaigns []*Campaign
	for resultsIterator.HasNext() {
		qr, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		if len(qr.Key) >= 9 && qr.Key[:9] == "donation_" {
			continue
		}
		var c Campaign
		if err := json.Unmarshal(qr.Value, &c); err != nil {
			return nil, err
		}
		campaigns = append(campaigns, &c)
	}
	return campaigns, nil
}

func (k *KindLedgerContract) CampaignExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	campaignJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read campaign %s: %v", id, err)
	}
	return campaignJSON != nil, nil
}

func (k *KindLedgerContract) GetCampaignHistory(ctx contractapi.TransactionContextInterface, campaignID string) ([]Donation, error) {
	it, err := ctx.GetStub().GetHistoryForKey(campaignID)
	if err != nil {
		return nil, err
	}
	defer it.Close()
	var donations []Donation
	for it.HasNext() {
		qr, err := it.Next()
		if err != nil {
			return nil, err
		}
		var campaign Campaign
		if err := json.Unmarshal(qr.Value, &campaign); err != nil {
			return nil, err
		}
		for _, donor := range campaign.Donors {
			donations = append(donations, Donation{CampaignID: campaignID, DonorID: donor.ID, DonorName: donor.Name, Amount: donor.Amount, DonatedAt: donor.DonatedAt})
		}
	}
	return donations, nil
}

func (k *KindLedgerContract) UpdateCampaignStatus(ctx contractapi.TransactionContextInterface, campaignID, status string) error {
	campaign, err := k.QueryCampaign(ctx, campaignID)
	if err != nil {
		return err
	}
	campaign.Status = status
	campaign.UpdatedAt = time.Now()
	campaignJSON, err := json.Marshal(campaign)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(campaignID, campaignJSON)
}

func (k *KindLedgerContract) GetTotalDonations(ctx contractapi.TransactionContextInterface) (float64, error) {
	campaigns, err := k.QueryAllCampaigns(ctx)
	if err != nil {
		return 0, err
	}
	total := 0.0
	for _, c := range campaigns {
		total += c.Raised
	}
	return total, nil
}
